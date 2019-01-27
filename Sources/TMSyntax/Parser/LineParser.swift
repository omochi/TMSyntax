import Foundation

internal final class LineParser {
    private static let backReferenceRegex: Regex = try! Regex(pattern: "\\\\(\\d+)", options: [])
    private static let invalidUnicode: Unicode.Scalar = Unicode.Scalar(0xFFFF)!
    private static let invalidString: String = String(String.UnicodeScalarView([invalidUnicode]))
    
    public init(line: String,
                stateStack: ParserStateStack,
                grammar: Grammar,
                isTraceEnabled: Bool)
    {
        self.line = line
        self.lineEndPosition = line.lineEndIndex
        self.position = line.startIndex
        self.isLineEnd = false
        self.stateStack = stateStack
        self.grammar = grammar
        self.tokens = []
        self.isTraceEnabled = isTraceEnabled
    }
    
    private let line: String
    private let lineEndPosition: String.Index
    private var position: String.Index
    private var isLineEnd: Bool
    private var stateStack: ParserStateStack
    private let grammar: Grammar
    private var tokens: [Token]
    private let isTraceEnabled: Bool
    
    public func parse() throws -> Parser.Result {
        while true {
            try parseLine()
            if isLineEnd {
                return Parser.Result(stateStack: stateStack,
                                     tokens: tokens)
            }
        }
    }
    
    private func parseLine() throws {
        removePastAnchor()
        let searchEnd = collectSearchEnd()
        let plans = collectMatchPlans()
        
        if isTraceEnabled {
            let positionInByte = line.utf8.distance(from: line.startIndex, to: position)
            trace("--- match plans, position \(positionInByte) ---")
            for (index, plan) in plans.enumerated() {
                trace("[\(index + 1)/\(plans.count)]\(plan)")
            }
            trace("------")
        }
        
        let searchRange = position..<searchEnd.position

        guard let (plan, result) = try search(line: line,
                                              range: searchRange,
                                              plans: plans) else
        {
            trace("no match, end line")
            
            extendOuterScope(range: searchRange)
            self.position = searchRange.upperBound
            
            switch searchEnd {
            case .beginCapture(let anchor):
                processHitAnchor(anchor)
            case .endPosition:
                processEndPosition()
            case .line:
                precondition(state.captureAnchors.isEmpty)
                isLineEnd = true
            }
            
            return
        }
        
        extendOuterScope(range: searchRange.lowerBound..<result[].lowerBound)
        self.position = result[].lowerBound
        
        switch searchEnd {
        case .beginCapture(let anchor):
            precondition(result[].lowerBound <= anchor.range.lowerBound)
            if result[].lowerBound == anchor.range.lowerBound {
                processHitAnchor(anchor)
            }
            return
        case .endPosition(let endPosition):
            precondition(result[].lowerBound <= endPosition)
            if result[].lowerBound == endPosition {
                processEndPosition()
                return
            }
        default:
            break
        }
        
        processMatch(plan: plan, result: result)
    }
    
    private var state: ParserState {
        get { return stateStack.top! }
        set { stateStack.top = newValue }
    }
    
    private func removePastAnchor() {
        var anchors = state.captureAnchors
        anchors.removeAll { (anchor) in
            anchor.range.upperBound <= self.position
        }
        state.captureAnchors = anchors
    }
    
    private func collectSearchEnd() -> SearchEnd {
        var anchors = state.captureAnchors.sorted { (a, b) in
            a.range.lowerBound < b.range.lowerBound
        }
        anchors = anchors.filter { (anchor) in
            self.position <= anchor.range.lowerBound
        }
        if let end = state.endPosition {
            anchors = anchors.filter { (anchor) in
                anchor.range.upperBound <= end
            }
        }
        if let anchor = anchors.first {
            return .beginCapture(anchor)
        }
        if let end = state.endPosition {
            return .endPosition(end)
        }
        return .line(lineEndPosition)
    }
    
    private func collectMatchPlans() -> [MatchPlan] {
        var plans: [MatchPlan] = []

        for rule in state.patterns {
            plans += collectEnterMatchPlans(rule: rule)
        }
        
        if let endPattern = state.endPattern {
            let endPlan = MatchPlan.endPattern(endPattern)
            if let yes = state.scopeRule?.applyEndPatternLast, yes {
                plans.append(endPlan)
            } else {
                plans.insert(endPlan, at: 0)
            }
        }
        
        return plans
    }
    
    private func collectEnterMatchPlans(rule: Rule) -> [MatchPlan] {
        switch rule.switcher {
        case .include(let rule):
            guard let target = rule.resolve(grammar: grammar) else {
                return []
            }
            return collectEnterMatchPlans(rule: target)
        case .match(let rule):
            return [.matchRule(rule)]
        case .scope(let rule):
            if let _ = rule.begin {
                return [.createBeginRule(rule)]
            } else {
                var plans: [MatchPlan] = []
                for rule in rule.patterns {
                    plans += collectEnterMatchPlans(rule: rule)
                }
                return plans
            }
        }
    }
        
    private func search(line: String,
                        range: Range<String.Index>,
                        plans: [MatchPlan])
        throws -> (plan: MatchPlan, result: Regex.Match)?
    {
        let patterns = plans.map { $0.pattern }
        
        guard let (index, result) = try search(line: line,
                                               range: range,
                                               patterns: patterns) else
        {
            return nil
        }
        
        return (plan: plans[index], result: result)
    }
    
    private func search(line: String,
                        range: Range<String.Index>,
                        patterns: [RegexPattern])
        throws -> (index: Int, result: Regex.Match)?
    {
        typealias Record = (index: Int, result: Regex.Match)
        
        var records: [Record] = []
        
        for (index, pattern) in patterns.enumerated() {
            let regex = try pattern.compile()
            if let match = regex.search(string: line, range: range) {
                records.append(Record(index: index, result: match))
            }
        }
        
        func cmp(_ a: Record, _ b: Record) -> Bool {
            let (ai, am) = a
            let (bi, bm) = b
            
            if am[].lowerBound != bm[].lowerBound {
                return am[].lowerBound < bm[].lowerBound
            }
            
            return ai < bi
        }
        
        return records.min(by: cmp)
    }
    
    private func processMatch(plan: MatchPlan, result regexMatch: Regex.Match) {
        trace("match!: \(plan)")
        
        switch plan {
        case .matchRule(let rule):
            var scopePath = state.scopePath
            if let scope = rule.scopeName {
                scopePath.append(scope)
            }
            
            let anchors = buildCaptureAnchor(regexMatch: regexMatch,
                                             captures: rule.captures)
            let newState = ParserState(rule: rule,
                                       phase: nil,
                                       patterns: [],
                                       captureAnchors: anchors,
                                       scopePath: scopePath,
                                       endPattern: nil,
                                       endPosition: regexMatch[].upperBound)
            trace("push state")
            pushState(newState)
        case .beginRule(let rule):
            var scopePath = state.scopePath
            if let scope = rule.scopeName {
                scopePath.append(scope)
            }
            
            let ruleEndPattern = rule.end!
            let endPattern = resolveEndPatternBackReference(end: ruleEndPattern,
                                                            beginMatchResult: regexMatch)
            
            let anchors = buildCaptureAnchor(regexMatch: regexMatch,
                                             captures: rule.beginCaptures)
            
            let newState = ParserState(rule: rule,
                                       phase: .pushContentAtEndPosition,
                                       patterns: rule.patterns,
                                       captureAnchors: anchors,
                                       scopePath: scopePath,
                                       endPattern: endPattern,
                                       endPosition: regexMatch[].upperBound)
            trace("push state")
            pushState(newState)
        case .endPattern:
            let rule = state.scopeRule!
            
            // end of contentName
            if let contentName = rule.contentName {
                trace("pop contentName")
                precondition(contentName == state.scopePath.last)
                state.scopePath.removeLast()
            }
            
            state.endPosition = regexMatch[].upperBound
            
            let anchors = buildCaptureAnchor(regexMatch: regexMatch,
                                             captures: rule.endCaptures)
            state.captureAnchors = anchors
        }
    }
    
    private func processHitAnchor(_ anchor: CaptureAnchor) {
        var scopePath = state.scopePath
        if let scope = anchor.attribute?.name {
            scopePath.append(scope)
        }
        
        let newState = ParserState(rule: nil,
                                   phase: nil,
                                   patterns: anchor.attribute?.patterns ?? [],
                                   captureAnchors: anchor.children,
                                   scopePath: scopePath,
                                   endPattern: nil,
                                   endPosition: anchor.range.upperBound)
        trace("push state: anchor")
        pushState(newState)
    }
    
    private func processEndPosition() {
        if let phase = state.phase {
            switch phase {
            case .pushContentAtEndPosition:
                let rule = state.scopeRule!
                trace("push contentName")
                if let contentName = rule.contentName {
                    state.scopePath.append(contentName)
                }
                state.phase = ParserState.Phase.content
                state.endPosition = nil
                return
            default:
                break
            }
        }
        
        trace("pop state")
        popState()
    }
    
    private func buildCaptureAnchor(regexMatch: Regex.Match,
                                    captures: CaptureAttributes?) -> [CaptureAnchor]
    {
        return CaptureAnchor.build(regexMatch: regexMatch,
                                   captures: captures)
    }
    
    private func resolveEndPatternBackReference(end: RegexPattern,
                                                beginMatchResult: Regex.Match) -> RegexPattern
    {
        var num = 0
        
        let newPattern = LineParser.backReferenceRegex.replace(string: end.value) { (match) in
            num += 1
            
            let captureIndex = Int(end.value[match[1]!])!
            
            guard let range = beginMatchResult[captureIndex] else {
                return LineParser.invalidString
            }
            return Regex.escape(String(line[range]))
        }
        
        if num == 0 {
            // return same object
            return end
        }
        
        return RegexPattern(newPattern, location: end.location)
    }
    
    private func extendOuterScope(range: Range<String.Index>) {
        guard !range.isEmpty else {
            return
        }
        
        let token = Token(range: range,
                          scopePath: state.scopePath)
        addToken(token)
    }
    
    private func pushState(_ newState: ParserState) {
        var newState = newState
        
        if let stateEnd = newState.endPosition,
            let currentEnd = self.state.endPosition,
            currentEnd < stateEnd
        {
            newState.endPosition = currentEnd
        }
        
        stateStack.stack.append(newState)
    }
    
    private func popState() {
        stateStack.stack.removeLast()
    }
    
    private func addToken(_ newToken: Token) {
        if var last = tokens.last {
            precondition(last.range.upperBound == newToken.range.lowerBound)
            
            // squash
//            if last.scopePath == newToken.scopePath {
//                last.range = last.range.lowerBound..<newToken.range.upperBound
//                tokens[tokens.count - 1] = last
//                return
//            }
        }
        
        tokens.append(newToken)
    }
    
    private func trace(_ string: String) {
        if isTraceEnabled {
            print("[Parser trace] \(string)")
        }
    }

}
