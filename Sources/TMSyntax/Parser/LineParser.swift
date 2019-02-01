import Foundation

internal final class LineParser {
    public init(line: String,
                lineIndex: Int,
                stateStack: ParserStateStack,
                grammar: Grammar,
                isTraceEnabled: Bool)
    {
        
        self.line = line
        self.lineIndex = lineIndex
        self.position = line.startIndex
        self.isLineEnd = false
        self.stateStack = stateStack
        self.grammar = grammar
        self.tokens = []
        self.isTraceEnabled = isTraceEnabled
    }
    
    private let line: String
    private let lineIndex: Int
    private var position: String.Index
    private var isLineEnd: Bool
    private var stateStack: ParserStateStack
    private let grammar: Grammar
    private var tokens: [Token]
    private let isTraceEnabled: Bool
    
    public func parse() throws -> Parser.Result {
        while !isLineEnd {
            try parseLine()
        }
        fixLineEndTokens()
        return Parser.Result(stateStack: stateStack,
                             tokens: tokens)
    }
    
    private func fixLineEndTokens() {
        let lineEndIndex = line.lastNewLineIndex
        while var token = tokens.last {
//            if token.range.upperBound <= lineEndIndex {
//                break
//            }
            
            if token.range.isEmpty,
                tokens.count >= 2
            {
                tokens.removeLast()
                continue
            }
            
            token.range = token.range.lowerBound..<lineEndIndex
            tokens[tokens.count - 1] = token
            break
        }
    }
    
    private func parseLine() throws {
        removePastAnchor()
        let searchEnd = self.searchEnd()
        let plans = collectMatchPlans()
        
        if isTraceEnabled {
            trace("--- match plans, position \(positionToIntForDebug(position)) ---")
            for (index, plan) in plans.enumerated() {
                trace("[\(index + 1)/\(plans.count)]\(plan)")
            }
            trace("------")
        }
        
        let searchRange = position..<searchEnd.position
        
        let mostLeftAnchor = self.mostLeftAnchor()

        guard let result = try search(line: line,
                                      lineIndex: lineIndex,
                                      range: searchRange,
                                      plans: plans,
                                      anchor: mostLeftAnchor) else
        {

            
            switch searchEnd {
            case .endPosition(let position):
                buildToken(to: searchRange.upperBound)
                trace("hit end position")
                processEndPosition(position)
            case .line(let position):
                let lineNewLinePosition = line.lastNewLineIndex
                if self.position <= lineNewLinePosition {
                    buildToken(to: lineNewLinePosition, allowEmpty: true)
                }
                trace("hit end of line")
                precondition(state.captureAnchors.isEmpty)
                advance(to: position)
                isLineEnd = true
            }
            
            return
        }
        
        switch result {
        case .regex(plan: let plan, matchResult: let matchResult):
            trace("regex match: \(plan)")
            buildToken(to: matchResult[].lowerBound)
            try processMatch(plan: plan, matchResult: matchResult)
        case .anchor(let anchor):
            trace("hit anchor")
            buildToken(to: anchor.range.lowerBound)
            processHitAnchor(anchor)
        }
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
    
    public enum SearchEnd {
        case endPosition(String.Index)
        case line(String.Index)
        
        public var position: String.Index {
            switch self {
            case .endPosition(let position),
                 .line(let position):
                return position
            }
        }
    }
    
    private func searchEnd() -> SearchEnd {
        if let end = state.endPosition {
            return .endPosition(end)
        }
        return .line(line.endIndex)
    }
    
    private func mostLeftAnchor() -> CaptureAnchor? {
        return state.captureAnchors.min { (a, b) in
            a.range.lowerBound < b.range.lowerBound
        }
    }
    
    private func collectMatchPlans() -> [MatchPlan] {
        var isInjectionEnabled: Bool = false
        
        switch state.phase {
        case .match,
             .scopeBegin,
             .scopeEnd:
            return []
        case .scopeContent:
            isInjectionEnabled = true
            break
        case .captureAnchor:
            isInjectionEnabled = false
            break
        }
        
        var plans: [MatchPlan] = []

        for rule in state.patterns {
            plans += collectEnterMatchPlans(position: .none,
                                            rule: rule)
        }
        
        if let endPattern = state.endPattern {
            let endPlan = MatchPlan.createEndPattern(pattern: endPattern,
                                                     beginMatchResult: state.beginMatchResult,
                                                     beginLineIndex: state.beginLineIndex)
            if let yes = state.scopeRule?.applyEndPatternLast, yes {
                plans.append(endPlan)
            } else {
                plans.insert(endPlan, at: 0)
            }
        }
        
        if isInjectionEnabled {
            // injection is back
            plans += collectInjectionMatchPlans()
        }
        
        return plans
    }
    
    private func collectEnterMatchPlans(position: ScopeMatchPosition,
                                        rule: Rule) -> [MatchPlan] {
        switch rule.switcher {
        case .include(let rule):
            guard let target = rule.resolve() else {
                return []
            }
            return collectEnterMatchPlans(position: position,
                                          rule: target)
        case .match(let rule):
            return [MatchPlan.createMatchRule(position: position,
                                              rule: rule)]
        case .scope(let rule):
            if let _ = rule.begin {
                return [MatchPlan.createBeginRule(position: position,
                                                  rule: rule)]
            } else {
                var plans: [MatchPlan] = []
                for rule in rule.patterns {
                    plans += collectEnterMatchPlans(position: position,
                                                    rule: rule)
                }
                return plans
            }
        }
    }
    
    private func collectInjectionMatchPlans() -> [MatchPlan] {
        var plans: [MatchPlan] = []
        
        var injections = grammar.injections
        
        if let ijs = grammar.repository?.injections {
            injections += ijs
        }
        
        for injection in injections {
            guard let result = injection.selector.match(path: state.scopePath) else {
                continue
            }
            
            plans += collectEnterMatchPlans(position: result.position,
                                            rule: injection.rule)
        }
        
        return plans
    }
    
    private func buildRegexMatchPlan(_ plan: MatchPlan) -> RegexMatchPlan {
        switch plan.pattern {
        case .match(let rule):
            return RegexMatchPlan(position: plan.position,
                                  pattern: rule.pattern,
                                  globalPosition: nil)
        case .begin(let rule):
            let begin = rule.begin!
            return RegexMatchPlan(position: plan.position,
                                  pattern: begin,
                                  globalPosition: nil)
        case .endPattern(pattern: let pattern,
                         beginMatchResult: let beginMatchResult,
                         beginLineIndex: let beginLineIndex):
            let globalPosition: String.Index?
            
            if let beginMatchResult = beginMatchResult,
                let beginLineIndex = beginLineIndex,
                lineIndex == beginLineIndex
            {
                globalPosition = beginMatchResult[].upperBound
            } else {
                globalPosition = nil
            }
            return RegexMatchPlan(position: plan.position,
                                  pattern: pattern,
                                  globalPosition: globalPosition)
        }
    }
    
    public enum SearchResult {
        case regex(plan: MatchPlan,
                   matchResult: Regex.MatchResult)
        case anchor(CaptureAnchor)
        
        public var leftIndex: String.Index {
            switch self {
            case .regex(plan: _, matchResult: let result): return result[].lowerBound
            case .anchor(let anchor): return anchor.range.lowerBound
            }
        }
        
        public var position: ScopeMatchPosition {
            switch self {
            case .regex(plan: let plan, matchResult: _): return plan.position
            case .anchor: return .none
            }
        }
    }
    
    private func search(line: String,
                        lineIndex: Int,
                        range: Range<String.Index>,
                        plans: [MatchPlan],
                        anchor: CaptureAnchor?)
        throws -> SearchResult?
    {
        let regexPlans = plans.map { buildRegexMatchPlan($0) }
        
        let regexResult = try searchRegex(line: line,
                                          range: range,
                                          plans: regexPlans)
        
        let regexResultBox = regexResult.map {
            SearchResult.regex(plan: plans[$0.index],
                               matchResult: $0.matchResult) }
        let anchorBox = anchor.map {
            SearchResult.anchor($0)
        }
        
        let best = minFromOptionals(regexResultBox, anchorBox) { (a, b) in
            compare(a, b,
                    { $0.leftIndex < $1.leftIndex },
                    { $0.position < $1.position })
        }
        
        return best
    }
    
    private func searchRegex(line: String,
                             range: Range<String.Index>,
                             plans: [RegexMatchPlan])
        throws -> (index: Int, matchResult: Regex.MatchResult)?
    {
        var plans = Array(plans.enumerated())
        
        plans.sort { (a, b) in
            compare(a, b,
                    { $0.element.position < $1.element.position },
                    { $0.offset < $1.offset })
        }
        
        typealias Record = (
            index: Int,
            position: ScopeMatchPosition,
            result: Regex.MatchResult)
        
        var records: [Record] = []
        
        for plan in plans {
            if let match = try plan.element.search(string: line, range: range) {
                if match[].lowerBound == range.lowerBound {
                    // absolute winner
                    return (index: plan.offset,
                            matchResult: match)
                }
                
                let record = Record(index: plan.offset,
                                    position: plan.element.position,
                                    result: match)
                records.append(record)                
            }
        }
        
        let bestOrNone = records.min { (a, b) in
            compare(a, b,
                    { $0.result[].lowerBound < $1.result[].lowerBound },
                    { $0.position < $1.position },
                    { $0.index < $1.index })
        }
        
        guard let best = bestOrNone else {
            return nil
        }
        
        return (index: best.index,
                matchResult: best.result)
    }
    
    private func processMatch(plan: MatchPlan, matchResult: Regex.MatchResult) throws {
        switch plan.pattern {
        case .match(let rule):
            if position == matchResult[].upperBound {
                trace("infinite loop detected. no advance match rule.")
                
                popStateIfWillNotBeEmpty()
                advance(to: line.endIndex)
                buildToken(to: position)
                return
            }
            
            var scopePath = state.scopePath
            if let scope = try rule.resolveScopeName(line: line, matchResult: matchResult) {
                scopePath.push(scope)
            }
            
            let anchor = buildCaptureAnchor(matchResult: matchResult,
                                            captures: rule.captures)
            let newState = ParserState(rule: rule,
                                       phase: .match,
                                       patterns: [],
                                       captureAnchors: anchor.mapToArray { $0 },
                                       scopePath: scopePath,
                                       contentName: nil,
                                       beginMatchResult: nil,
                                       beginLineIndex: nil,
                                       endPattern: nil,
                                       endPosition: matchResult[].upperBound)
            trace("push state: match")
            pushState(newState)
            
            advance(to: matchResult[].lowerBound)
        case .begin(let rule):
            var scopePath = state.scopePath
            if let scopeName = try rule.resolveScopeName(line: line, matchResult: matchResult) {
                scopePath.push(scopeName)
            }
            
            let contentName = try rule.resolveContentName(line: line, matchResult: matchResult)
            
            let anchor = buildCaptureAnchor(matchResult: matchResult,
                                             captures: rule.beginCaptures)
            
            let endPattern = try rule.resolveEnd(line: line, matchResult: matchResult)
            
            let newState = ParserState(rule: rule,
                                       phase: .scopeBegin,
                                       patterns: rule.patterns,
                                       captureAnchors: anchor.mapToArray { $0 },
                                       scopePath: scopePath,
                                       contentName: contentName,
                                       beginMatchResult: matchResult,
                                       beginLineIndex: lineIndex,
                                       endPattern: endPattern,
                                       endPosition: matchResult[].upperBound)
            trace("push state: scopeBegin \(positionToIntForDebug(position))")
            pushState(newState)
            
            advance(to: matchResult[].lowerBound)
        case .endPattern:
            let rule = state.scopeRule!
            
            trace("move state: scopeContent->scopeEnd \(positionToIntForDebug(position))")
            
            // end of contentName
            if let contentName = state.contentName {
                precondition(contentName == state.scopePath.top)
                state.scopePath.pop()
            }
            
            let anchors = buildCaptureAnchor(matchResult: matchResult,
                                             captures: rule.endCaptures)
            
            state.phase = ParserState.Phase.scopeEnd
            state.endPosition = matchResult[].upperBound
            state.captureAnchors = anchors.mapToArray { $0 }
            
            advance(to: matchResult[].lowerBound)
        }
    }
    
    private func processHitAnchor(_ anchor: CaptureAnchor) {
        var scopePath = state.scopePath
        if let scope = anchor.attribute?.name {
            scopePath.push(scope)
        }
        
        let newState = ParserState(rule: nil,
                                   phase: .captureAnchor,
                                   patterns: anchor.attribute?.patterns ?? [],
                                   captureAnchors: anchor.children,
                                   scopePath: scopePath,
                                   contentName: nil,
                                   beginMatchResult: nil,
                                   beginLineIndex: nil,
                                   endPattern: nil,
                                   endPosition: anchor.range.upperBound)
        trace("push state: anchor")
        pushState(newState)
        
        advance(to: anchor.range.lowerBound)
    }
    
    private func processEndPosition(_ position: String.Index) {
        switch state.phase {
        case .scopeBegin:
            let rule = state.scopeRule!
            trace("move state: scopeBegin->scopeContent \(positionToIntForDebug(position))")
            if let contentName = state.contentName {
                state.scopePath.push(contentName)
            }
            
            state.phase = ParserState.Phase.scopeContent
            state.endPosition = nil
            
            advance(to: position)
        default:
            trace("pop state")
            popState()
            advance(to: position)
        }
    }
    
    private func buildCaptureAnchor(matchResult: Regex.MatchResult,
                                    captures: CaptureAttributes?) -> CaptureAnchor?
    {
        let anchors = CaptureAnchor.build(matchResult: matchResult,
                                          captures: captures)
        return anchors.first
    }
    
    private func buildToken(to end: String.Index, allowEmpty: Bool = false) {
        let start = tokens.last?.range.upperBound ?? line.startIndex
        
        guard allowEmpty || start < end else {
            return
        }

        let token = Token(range: start..<end,
                          scopePath: state.scopePath)
        _addToken(token)
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
    
    private func popStateIfWillNotBeEmpty() {
        guard stateStack.stack.count >= 2 else {
            return
        }
        popState()
    }
    
    private func _addToken(_ newToken: Token) {
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
    
    private func advance(to position: String.Index) {
        trace("advance \(positionToIntForDebug(position))")
        self.position = position
    }
    
    private func positionToIntForDebug(_ position: String.Index) -> Int {
        return line.distance(from: line.startIndex, to: position)
    }
    
    private func trace(_ string: String) {
        if isTraceEnabled {
            print("[Parser trace] \(string)")
        }
    }

}
