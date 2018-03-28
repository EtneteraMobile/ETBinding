import UIKit
import PlaygroundSupport

public let etnColor = UIColor(red: 224/255.0, green: 101/255.0, blue: 54/255.0, alpha: 1.0)

public final class Container : UIView {
    // MARK: - Variables
    // MARK: public
    public var isRotationEnabled: Bool {
        didSet {
            rotateButton.isHidden = !isRotationEnabled
        }
    }

    public let content: UIView

    // MARK: private

    private let width: CGFloat = 375
    private let height: CGFloat = 667
    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!

    private let rotateButton: UIButton = {
        let b = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 84, height: 44)))
        b.setTitle("Rotate", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .highlighted)
        b.backgroundColor = etnColor
        b.addTarget(self, action: #selector(Container.rotate), for: .touchUpInside)
        return b
    }()

    // MARK: - Initialization

    public init(isRotationEnabled: Bool = true) {
        self.isRotationEnabled = isRotationEnabled
        self.content = UIView(frame: .zero)

        super.init(frame: CGRect(origin: .zero, size: CGSize(width: 700, height: 700)))
        backgroundColor = UIColor(white: 0.85, alpha: 1.0)
        content.backgroundColor = .white

        addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = content.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
        heightConstraint = content.heightAnchor.constraint(equalToConstant: height)
        heightConstraint.isActive = true
        content.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        content.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        addSubview(rotateButton)
        rotateButton.isHidden = !isRotationEnabled

        PlaygroundPage.current.needsIndefiniteExecution = true
        PlaygroundPage.current.liveView = self
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions
    // MARK: private

    @objc private func rotate() {
        layoutIfNeeded()
        UIView.animate(withDuration: 0.3) {
            self.widthConstraint.constant = self.widthConstraint.constant == self.width ? self.height : self.width
            self.heightConstraint.constant = self.heightConstraint.constant == self.height ? self.width : self.height
            self.content.subviews.forEach {
                $0.setNeedsLayout()
            }
            self.layoutIfNeeded()
        }
    }
}
