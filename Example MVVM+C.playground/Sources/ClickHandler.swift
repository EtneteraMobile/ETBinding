import Foundation

public class ClickHandler {
    let onClick: () -> Void
    public init(onClick: @escaping () -> Void) {
        self.onClick = onClick
    }
    @objc public func click() {
        onClick()
    }
}
