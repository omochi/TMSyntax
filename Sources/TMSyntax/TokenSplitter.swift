import Foundation

/*
 適切なデータ構造が欲しい
 */
public class TokenSplitter {
    public init(rootToken: Token) {
        self._tokens = [rootToken]
    }

    public var tokens: [Token] {
        return _tokens
    }
    
    private var _tokens: [Token]
    
    public func add(range newRange: Range<String.Index>,
                    scopeName: ScopeName)
    {
        var index = _tokens.binarySearch { $0.range.lowerBound < newRange.lowerBound }
        if index >= _tokens.count {
            index -= 1
        }        
        if newRange.lowerBound < _tokens[index].range.lowerBound {
            index -= 1
        }
        
        guard _tokens[index].range.lowerBound <= newRange.lowerBound &&
            newRange.upperBound <= _tokens[index].range.upperBound else
        {
            fatalError("new range splitting is not supported")
        }
        
        if _tokens[index].range.lowerBound < newRange.lowerBound {
            // left split
            
            var leftToken = _tokens[index]
            leftToken.range = leftToken.range.lowerBound..<newRange.lowerBound
            _tokens.insert(leftToken, at: index)
            index += 1
        }
        
        if newRange.upperBound < _tokens[index].range.upperBound {
            // right split
            
            var rightToken = _tokens[index]
            rightToken.range = newRange.upperBound..<rightToken.range.upperBound
            _tokens.insert(rightToken, at: index + 1)
        }
        
        var newToken = _tokens[index]
        newToken.range = newRange
        newToken.scopes.append(scopeName)
        _tokens[index] = newToken
    }
    
}
