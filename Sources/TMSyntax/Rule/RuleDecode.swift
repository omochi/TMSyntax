extension Rule {
    public static func decode(from decoder: Decoder) throws -> Rule {
        let loc = decoder.sourceLocation!
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let target = try c.decodeIfPresent(IncludeTarget.self, forKey: .include) {
            return IncludeRule(sourceLocation: decoder.sourceLocation,
                               target: target)
        }
        
        let scopeName = try c.decodeIfPresent(ScopeName.self, forKey: .name)
        
        if let matchPattern = try c.decodeIfPresent(RegexPattern.self, forKey: .match) {
            guard let scopeName = scopeName else {
                throw DecodingError(location: loc, "name not found in match rule")
            }
            
            return MatchRule(sourceLocation: decoder.sourceLocation,
                             pattern: matchPattern,
                             scopeName: scopeName)
        }
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)
        
        if let begin = try c.decodeIfPresent(RegexPattern.self, forKey: .begin) {
            var beginCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .beginCaptures)
            
            guard let end = try c.decodeIfPresent(RegexPattern.self, forKey: .end) else {
                throw DecodingError(location: loc, "end not found in begin rule")
            }
            var endCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .endCaptures)
            
            if let captures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .captures) {
                beginCaptures = captures
                endCaptures = captures
            }
            
            let cond = BeginEndCondition(begin: begin,
                                         beginCaptures: beginCaptures,
                                         end: end,
                                         endCaptures: endCaptures)
            
            return ScopeRule(sourceLocation: decoder.sourceLocation,
                             condition: .beginEnd(cond),
                             patterns: patterns,
                             repository: repository,
                             scopeName: scopeName)
        }
        
        return ScopeRule(sourceLocation: decoder.sourceLocation,
                         condition: .none,
                         patterns: patterns,
                         repository: repository,
                         scopeName: nil)
    }
}
