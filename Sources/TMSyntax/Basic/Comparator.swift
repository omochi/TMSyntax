import Foundation

func compare<T>(_ a: T, _ b: T,
                _ cmp1: @escaping (T, T) -> Bool,
                _ cmp2: @escaping (T, T) -> Bool)
    -> Bool
{
    if cmp1(a, b) { return true }
    if cmp1(b, a) { return false }
    return cmp2(a, b)
}

func compare<T>(_ a: T, _ b: T,
                _ cmp1: @escaping (T, T) -> Bool,
                _ cmp2: @escaping (T, T) -> Bool,
                _ cmp3: @escaping (T, T) -> Bool)
    -> Bool
{
    if cmp1(a, b) { return true }
    if cmp1(b, a) { return false }
    if cmp2(a, b) { return true }
    if cmp2(b, a) { return false }
    return cmp3(a, b)
}
