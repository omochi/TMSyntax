internal protocol CopyInitializable {
    init(copy: Self)
}

extension CopyInitializable {
    public init(copy: Self) {
        self = copy
    }
}
