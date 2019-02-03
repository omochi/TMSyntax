import Foundation

internal final class LineParser {
    public init(line: String,
                lineIndex: Int,
                lineCount: Int,
                stateStack: ParserStateStack,
                grammar: Grammar,
                isTraceEnabled: Bool)
    {
        
        self.line = line
        self.lineIndex = lineIndex
        self.lineCount = lineCount
        self.position = line.startIndex
        self.isLineEnd = false
        self.stateStack = stateStack
        self.grammar = grammar
        self.tokens = []
        self.isTraceEnabled = isTraceEnabled
    }
    
    private let line: String
    private let lineIndex: Int
    private let lineCount: Int
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

        let searchRange = position..<max(searchEnd.position, position)
        
        let mostLeftAnchor = self.mostLeftAnchor()
        
        if isTraceEnabled {
            trace("--- match plans, position \(positionStringForDebug(position)) ---")
            for (index, plan) in plans.enumerated() {
                trace("[\(index + 1)/\(plans.count)]\(plan)")
            }
            if let anchor = mostLeftAnchor {
                trace("[anchor] capture[\(anchor.captureIndex)] \(rangeStringForDebug(anchor.range))")
            }
            trace("------")
        }
        
        guard let result = try search(line: line,
                                      lineIndex: lineIndex,
                                      lineRange: state.captureRange ?? (line.startIndex..<line.endIndex),
                                      searchRange: searchRange,
                                      plans: plans,
                                      anchor: mostLeftAnchor) else
        {
            switch searchEnd {
            case .endPosition(let position):
                trace("hit end position")
                buildToken(to: searchRange.upperBound)
                processEndPosition(position)
            case .line(let position):
                trace("hit end of line")
                let lineNewLinePosition = line.lastNewLineIndex
                if self.position <= lineNewLinePosition {
                    buildToken(to: lineNewLinePosition, allowEmpty: true)
                }
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
            trace("hit anchor: capture[\(anchor.captureIndex)] \(rangeStringForDebug(anchor.range))")
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
        var endPosition: String.Index? = nil
        
        switch state.phase {
        case .match(let match):
            endPosition.squash(match.matchResult[].upperBound) { min($0, $1) }
        case .beginEndBegin(let begin):
            endPosition.squash(begin.matchResult[].upperBound) { min($0, $1) }
        case .beginEndEnd(_, let end):
            endPosition.squash(end.matchResult[].upperBound) { min($0, $1) }
        case .beginWhileBegin(let begin):
            endPosition.squash(begin.matchResult[].upperBound) { min($0, $1) }
        case .rootContent,
             .beginEndContent,
             .captureAnchor:
            break
        }
        
        endPosition.squash(state.captureRange?.upperBound) { min($0, $1) }
        
        if let endPosition = endPosition {
            return .endPosition(endPosition)
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
             .beginEndBegin,
             .beginEndEnd,
             .beginWhileBegin:
            return []
        case .rootContent,
             .beginEndContent:
            isInjectionEnabled = true
            break
        case .captureAnchor:
            isInjectionEnabled = false
            break
        }
        
        var plans: [MatchPlan] = []
        
        for rule in state.patterns {
            plans += collectEnterMatchPlans(rulePosition: .none,
                                            rule: rule,
                                            base: grammar)
        }
        
        if case .beginEndContent(let beginState) = state.phase {
            let endPlan = MatchPlan.createEndPattern(state: beginState)
            if beginState.rule.applyEndPatternLast {
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
    
    private func collectEnterMatchPlans(rulePosition: MatchRulePosition,
                                        rule: Rule,
                                        base: Grammar)
        -> [MatchPlan]
    {
        if !rule.isEnabled {
            return []
        }
        
        switch rule.switcher {
        case .include(let rule):
            guard let target = rule.resolve(base: base) else {
                return []
            }
            return collectEnterMatchPlans(rulePosition: rulePosition,
                                          rule: target,
                                          base: base)
        case .match(let rule):
            return [MatchPlan.createMatchRule(rulePosition: rulePosition,
                                              rule: rule)]
        case .hub(let rule):
            var plans: [MatchPlan] = []
            for rule in rule.patterns {
                plans += collectEnterMatchPlans(rulePosition: rulePosition,
                                                rule: rule,
                                                base: base)
            }
            return plans
        case .beginEnd(let rule):
            return [MatchPlan.createBeginRule(rulePosition: rulePosition,
                                              rule: rule)]
        case .beginWhile(let rule):
            return [MatchPlan.createBeginRule(rulePosition: rulePosition,
                                              rule: rule)]
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
            
            plans += collectEnterMatchPlans(rulePosition: result.position,
                                            rule: injection.rule,
                                            base: grammar)
        }
        
        return plans
    }
    
    private func buildRegexMatchPlan(_ plan: MatchPlan,
                                     position: String.Index)
        -> RegexMatchPlan
    {
        switch plan.pattern {
        case .match(let rule):
            return RegexMatchPlan(rulePosition: plan.rulePosition,
                                  pattern: rule.pattern,
                                  globalPosition: position)
        case .beginEndBegin(let rule):
            return RegexMatchPlan(rulePosition: plan.rulePosition,
                                  pattern: rule.begin,
                                  globalPosition: position)
        case .beginWhile(let rule):
            return RegexMatchPlan(rulePosition: plan.rulePosition,
                                  pattern: rule.begin,
                                  globalPosition: position)
        case .beginEndEnd(let beginState):
            let globalPosition: String.Index?
            
            if lineIndex == beginState.lineIndex {
                globalPosition = beginState.matchResult[].upperBound
            } else {
                globalPosition = nil
            }
            
            return RegexMatchPlan(rulePosition: plan.rulePosition,
                                  pattern: beginState.endPattern,
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
        
        public var position: MatchRulePosition {
            switch self {
            case .regex(plan: let plan, matchResult: _): return plan.rulePosition
            case .anchor: return .none
            }
        }
    }
    
    private func search(line: String,
                        lineIndex: Int,
                        lineRange: Range<String.Index>,
                        searchRange: Range<String.Index>,
                        plans: [MatchPlan],
                        anchor: CaptureAnchor?)
        throws -> SearchResult?
    {
        let regexPlans = plans.map {
            buildRegexMatchPlan($0,
                                position: searchRange.lowerBound)
        }
        
        let regexResult = try searchRegex(line: line,
                                          lineIndex: lineIndex,
                                          lineRange: lineRange,
                                          searchRange: searchRange,
                                          plans: regexPlans)
        
        let regexResultBox = regexResult.map {
            SearchResult.regex(plan: plans[$0.index],
                               matchResult: $0.matchResult) }
        let anchorBox = anchor.map {
            SearchResult.anchor($0)
        }
        
        func cmpSBStrPos(_ a: SearchResult, b: SearchResult) -> Bool {
            return a.leftIndex < b.leftIndex
        }
        func cmpSBRulePos(_ a: SearchResult, b: SearchResult) -> Bool {
            return a.position < b.position
        }
        
        let results: [SearchResult] = [regexResultBox, anchorBox].compact()
            .sorted { (a: SearchResult, b: SearchResult) -> Bool in
                compare(a, b,
                        cmpSBStrPos,
                        cmpSBRulePos)
        }
        
        return results.first
    }
    
    private func searchRegex(line: String,
                             lineIndex: Int,
                             lineRange: Range<String.Index>,
                             searchRange: Range<String.Index>,
                             plans: [RegexMatchPlan])
        throws -> (index: Int, matchResult: Regex.MatchResult)?
    {
        var plans = Array(plans.enumerated())
        
        func cmpPlanMatchPos(a: (offset: Int, element: RegexMatchPlan),
                             b: (offset: Int, element: RegexMatchPlan)) -> Bool {
            return a.element.rulePosition < b.element.rulePosition
        }
        
        func cmpPlanOffset(a: (offset: Int, element: RegexMatchPlan),
                           b: (offset: Int, element: RegexMatchPlan)) -> Bool {
            return a.offset < b.offset
        }
        
        
        plans.sort { (a, b) in
            compare(a, b,
                    cmpPlanMatchPos,
                    cmpPlanOffset)
        }
        
        typealias Record = (
            index: Int,
            position: MatchRulePosition,
            result: Regex.MatchResult)
        
        func cmpRecordStrPos(a: Record, b: Record) -> Bool {
            return a.result[].lowerBound < b.result[].lowerBound
        }
        func cmpRecordMatchPos(a: Record, b: Record) -> Bool {
            return a.position < b.position
        }
        func cmpRecordIndex(a: Record, b: Record) -> Bool {
            return a.index < b.index
        }
        
        var records: [Record] = []
        
        for plan in plans {
            let regex = try plan.element.pattern.compile()
            
            if let match = searchRegex(regex: regex,
                                       line: line,
                                       lineIndex: lineIndex,
                                       lineRange: lineRange,
                                       searchRange: searchRange,
                                       globalPosition: plan.element.globalPosition)
            {
                if match[].lowerBound == searchRange.lowerBound {
                    // absolute winner
                    return (index: plan.offset,
                            matchResult: match)
                }
                
                let record = Record(index: plan.offset,
                                    position: plan.element.rulePosition,
                                    result: match)
                records.append(record)                
            }
        }
        
        let bestOrNone = records.min { (a: Record, b: Record) -> Bool in
            compare(a, b,
                    cmpRecordStrPos,
                    cmpRecordMatchPos,
                    cmpRecordIndex)
        }
        
        guard let best = bestOrNone else {
            return nil
        }
        
        return (index: best.index,
                matchResult: best.result)
    }
    
    private func searchRegex(regex: Regex,
                             line: String,
                             lineIndex: Int,
                             lineRange: Range<String.Index>,
                             searchRange: Range<String.Index>,
                             globalPosition: String.Index?)
        -> Regex.MatchResult?
    {
        var options: Regex.SearchOptions = []
        
        if 0 < lineIndex ||
            line.startIndex < lineRange.lowerBound
        {
            options.insert(.notBeginOfString)
        }
        if lineIndex < lineCount - 1 ||
            lineRange.upperBound < line.endIndex
        {
            options.insert(.notEndOfString)
        }

        guard let result = regex.search(string: line[lineRange],
                                        range: searchRange,
                                        globalPosition: globalPosition,
                                        options: options) else
        {
            return nil
        }
        
        return result
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
            
            let scopePath = newScopePath(try rule.resolveScopeName(line: line,
                                                                   matchResult: matchResult))
            
            let anchor = try buildCaptureAnchor(matchResult: matchResult,
                                                captures: rule.captures,
                                                line: line)
            
            let matchState = ParserState.Match(rule: rule,
                                               matchResult: matchResult)
            
            let newState = ParserState(phase: .match(matchState),
                                       patterns: [],
                                       captureAnchors: anchor.mapToArray { $0 },
                                       scopePath: scopePath,
                                       whileConditions: state.whileConditions,
                                       captureRange: state.captureRange)
            trace("push state: match")
            pushState(newState)
            
            advance(to: matchResult[].lowerBound)
        case .beginEndBegin(let rule):
            if position == matchResult[].upperBound,
                state.phase.rule === rule
            {
                trace("infinite loop detected. no advance recursive begin rule.")
                
                advance(to: line.endIndex)
                buildToken(to: position)
                
                popState()
                return
            }
            
            let scopePath = newScopePath(try rule.resolveScopeName(line: line, matchResult: matchResult))
            
            let contentName = try rule.resolveContentName(line: line, matchResult: matchResult)
            
            let anchor = try buildCaptureAnchor(matchResult: matchResult,
                                                captures: rule.beginCaptures,
                                                line: line)
            
            let endPattern = try rule.resolveEnd(line: line, matchResult: matchResult)
            
            let beginState = ParserState.BeginEndBegin(rule: rule,
                                                       matchResult: matchResult,
                                                       lineIndex: lineIndex,
                                                       endPattern: endPattern,
                                                       contentName: contentName)
            
            let newState = ParserState(phase: .beginEndBegin(beginState),
                                       patterns: rule.patterns,
                                       captureAnchors: anchor.mapToArray { $0 },
                                       scopePath: scopePath,
                                       whileConditions: state.whileConditions,
                                       captureRange: state.captureRange)
            trace("push state: beginEndBegin \(positionStringForDebug(position))")
            pushState(newState)
            
            advance(to: matchResult[].lowerBound)
        case .beginEndEnd(let beginState):
            if lineIndex == beginState.lineIndex,
                beginState.matchResult[].lowerBound == matchResult[].upperBound
            {
                trace("infinite loop detected. no advance after end rule.")
                
                advance(to: line.endIndex)
                buildToken(to: position)
                
                popState()
                return
            }
            
            trace("move state: beginEndContent -> beginEndEnd \(positionStringForDebug(position))")
            
            // end of contentName
            if let contentName = beginState.contentName {
                precondition(contentName == state.scopePath.top)
                state.scopePath.pop()
            }
            
            let anchors = try buildCaptureAnchor(matchResult: matchResult,
                                                 captures: beginState.rule.endCaptures,
                                                 line: line)
            
            let endState = ParserState.BeginEndEnd(matchResult: matchResult)
            
            state.phase = ParserState.Phase.beginEndEnd(beginState, endState)
            state.captureAnchors = anchors.mapToArray { $0 }
            
            advance(to: matchResult[].lowerBound)
        case .beginWhile(let rule):
            if position == matchResult[].upperBound,
                state.phase.rule === rule
            {
                trace("infinite loop detected. no advance recursive begin rule.")
                
                advance(to: line.endIndex)
                buildToken(to: position)
                
                popState()
                return
            }
            
            let scopePath = newScopePath(try rule.resolveScopeName(line: line, matchResult: matchResult))
            
            let contentName = try rule.resolveContentName(line: line, matchResult: matchResult)
            
            let anchor = try buildCaptureAnchor(matchResult: matchResult,
                                                captures: rule.beginCaptures,
                                                line: line)
            
            let whilePattern = try rule.resolveWhile(line: line, matchResult: matchResult)
            
            var whileConditions = state.whileConditions
            
            let cond = ParserState.WhileCondition(rule: rule,
                                                  condition: whilePattern)
            whileConditions.append(cond)
            
            let whileState = ParserState.BeginWhileState(rule: rule,
                                                         matchResult: matchResult,
                                                         lineIndex: lineIndex,
                                                         whilePattern: whilePattern,
                                                         contentName: contentName)
            
            let newState = ParserState(phase: .beginWhileBegin(whileState),
                                       patterns: rule.patterns,
                                       captureAnchors: anchor.mapToArray { $0 },
                                       scopePath: scopePath,
                                       whileConditions: whileConditions,
                                       captureRange: state.captureRange)
            trace("push state: beginWhileBegin \(positionStringForDebug(position))")
            pushState(newState)
            
            advance(to: matchResult[].lowerBound)
        }
    }
    
    private func processHitAnchor(_ anchor: CaptureAnchor) {
        let scopePath = newScopePath(anchor.attribute?.name)
        
        let newState = ParserState(phase: .captureAnchor,
                                   patterns: anchor.attribute?.patterns ?? [],
                                   captureAnchors: anchor.children,
                                   scopePath: scopePath,
                                   whileConditions: state.whileConditions,
                                   captureRange: newCaptureRange(anchor.range))
        trace("push state: anchor")
        pushState(newState)
        
        advance(to: anchor.range.lowerBound)
    }
    
    private func processEndPosition(_ position: String.Index) {
        switch state.phase {
        case .beginEndBegin(let beginState):
            trace("move state: beginEndBegin -> beginEndContent \(positionStringForDebug(position))")
            
            state.scopePath = newScopePath(beginState.contentName)            
            state.phase = ParserState.Phase.beginEndContent(beginState)
            
            advance(to: position)
        default:
            trace("pop state")
            popState()
            advance(to: position)
        }
    }
    
    private func buildCaptureAnchor(matchResult: Regex.MatchResult,
                                    captures: CaptureAttributes?,
                                    line: String)
        throws -> CaptureAnchor?
    {
        let anchors = try CaptureAnchor.build(matchResult: matchResult,
                                              captures: captures,
                                              line: line)
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
        
        trace("token " +
            " \(rangeStringForDebug(token.range))" +
            " \(token.scopePath)")
    }
    
    private func newScopePath(_ scope: ScopeName?) -> ScopePath {
        var path = state.scopePath
        if let scope = scope {
            path.items.append(scope)
        }
        return path
    }
    
    private func newCaptureRange(_ range: Range<String.Index>) -> Range<String.Index>? {
        return state.captureRange.squashed(range) { (a, b) in
            max(a.lowerBound, b.lowerBound)..<min(a.upperBound, b.upperBound)
        }
    }
    
    private func pushState(_ newState: ParserState) {
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
        tokens.append(newToken)
    }
    
    private func advance(to position: String.Index) {
        trace("advance \(positionStringForDebug(position))")
        self.position = position
    }
    
    private func positionStringForDebug(_ position: String.Index) -> String {
        let pos = line.distance(from: line.startIndex, to: position)
        return "\(pos)"
    }
    
    private func rangeStringForDebug(_ range: Range<String.Index>) -> String {
        let low = line.distance(from: line.startIndex, to: range.lowerBound)
        let up = line.distance(from: line.startIndex, to: range.upperBound)
        return "\(low)..<\(up)"
    }
    
    private func trace(_ string: @autoclosure () -> String) {
        if isTraceEnabled {
            print("[Parser trace] \(string())")
        }
    }
    
}
