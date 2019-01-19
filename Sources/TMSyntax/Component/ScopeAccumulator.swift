import Foundation

public final class ScopeAccumulator {
    public struct Item {
        public var range: Range<String.Index>
        public var scope: ScopeName
        
        public init(range: Range<String.Index>,
                    scope: ScopeName)
        {
            self.range = range
            self.scope = scope
        }
    }
    
    public enum Script : Equatable {
        case push(Int)
        case pop(Int)
    }
    
    public var items: [Item] = []
    
    public init() {}
    
    public func buildScripts() -> [Script] {
        var scripts: [Script] = []
        
        for (newItemIndex, newItem) in items.enumerated() {
            var insertIndex = scripts.count
            for (scriptIndex, script) in scripts.enumerated() {
                let scriptPosition = self.scriptPosition(script)
                if newItem.range.lowerBound < scriptPosition {
                    insertIndex = scriptIndex
                    break
                }
            }
            
            scripts.insert(Script.push(newItemIndex), at: insertIndex)
            
            insertIndex = 0
            for (scriptIndex, script) in scripts.enumerated().reversed() {
                let scriptPosition = self.scriptPosition(script)
                if scriptPosition < newItem.range.upperBound {
                    insertIndex = scriptIndex
                    break
                }
            }
            
            scripts.insert(Script.pop(newItemIndex), at: insertIndex + 1)
        }
        
        return scripts        
    }
    
    public func scriptPosition(_ script: Script) -> String.Index {
        switch script {
        case .push(let itemIndex):
            let item = items[itemIndex]
            return item.range.lowerBound
        case .pop(let itemIndex):
            let item = items[itemIndex]
            return item.range.upperBound
        }
    }
 
    public func buildTokens() -> [Token] {
        let scripts = self.buildScripts()
 
        
        var tokens: [Token] = []
        var stack: [Int] = []
        var position: String.Index?
        
        var scriptIndex = 0
        while true {
            if scriptIndex == scripts.count {
                break
            }
            
            var newStack = stack
            let scriptPosition = self.scriptPosition(scripts[scriptIndex])
            
            for i in scriptIndex..<scripts.count {
                let scr = scripts[i]
                if scriptPosition != self.scriptPosition(scr) {
                    break
                }
                // same position script
                
                scriptIndex += 1
                switch scr {
                case .push(let itemIndex):
                    newStack.append(itemIndex)
                case .pop(let itemIndex):
                    newStack.removeAll { $0 == itemIndex }
                }
            }
            
            if let startPosition = position {
                let token = Token(range: startPosition..<scriptPosition,
                                  scopes: stack.map { items[$0].scope })
                tokens.append(token)
            } else {
                // first position
            }
            position = scriptPosition
            stack = newStack
        }
        
        precondition(stack.isEmpty)
        
        return tokens
    }
}
