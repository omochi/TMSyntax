extension Rule {
    public enum CodingKeys : String, CodingKey {
        case disabled
        case include
        case match
        case name
        case patterns
        case repository
        case begin
        case beginCaptures
        case end
        case endCaptures
        case `while`
        case whileCaptures
        case captures
        case contentName
        case applyEndPatternLast
    }
    
    public static func decode(from decoder: Decoder) throws -> Rule {
        let sourceLocation = decoder.sourceLocation
        
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        let disabled = try c.decodeIfPresent(Int.self, forKey: .disabled) ?? 0
        let isEnabled: Bool = disabled == 0
        
        if let target = try c.decodeIfPresent(IncludeTarget.self, forKey: .include) {
            return IncludeRule(sourceLocation: sourceLocation,
                               isEnabled: isEnabled,
                               target: target)
        }
        
        let scopeName = try c.decodeIfPresent(ScopeName.self, forKey: .name)
        
        if let matchPattern = try c.decodeIfPresent(RegexPattern.self, forKey: .match) {           
            let captures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .captures)
            
            return MatchRule(sourceLocation: sourceLocation,
                             isEnabled: isEnabled,
                             pattern: matchPattern,
                             scopeName: scopeName,
                             captures: captures)
        }
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)
        
        guard let begin = try c.decodeIfPresent(RegexPattern.self, forKey: .begin) else {
            return HubRule(sourceLocation: sourceLocation,
                           isEnabled: isEnabled,
                           patterns: patterns,
                           repository: repository)
        }
        
        var beginCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .beginCaptures)
        var endCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .endCaptures)
        var whileCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .whileCaptures)

        let contentName: ScopeName? = try c.decodeIfPresent(ScopeName.self, forKey: .contentName)
        let applyEndPatternLast: Bool = try c.decodeIfPresent(Bool.self, forKey: .applyEndPatternLast) ?? false
        
        if let captures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .captures) {
            beginCaptures = beginCaptures ?? captures
            endCaptures = endCaptures ?? captures
            whileCaptures = whileCaptures ?? captures
        }
        
        if let end = try c.decodeIfPresent(RegexPattern.self, forKey: .end) {
            return BeginEndRule(sourceLocation: sourceLocation,
                                isEnabled: isEnabled,
                                begin: begin,
                                beginCaptures: beginCaptures,
                                end: end,
                                endCaptures: endCaptures,
                                contentName: contentName,
                                applyEndPatternLast: applyEndPatternLast,
                                patterns: patterns,
                                repository: repository,
                                scopeName: scopeName)
        } else if let while_ = try c.decodeIfPresent(RegexPattern.self, forKey: .while) {
            return BeginWhileRule(sourceLocation: sourceLocation,
                                  isEnabled: isEnabled,
                                  begin: begin,
                                  beginCaptures: beginCaptures,
                                  while: while_,
                                  whileCaptures: whileCaptures,
                                  contentName: contentName,
                                  patterns: patterns,
                                  repository: repository,
                                  scopeName: scopeName)
        }
        
        throw Parser.Error.noEndKindPattern(sourceLocation)
    }
}
