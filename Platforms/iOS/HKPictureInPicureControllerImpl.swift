import Foundation

class HKPictureInPicureControllerImpl: HKPictureInPicureController {
    static let margin: CGFloat = 16
    static let position: HKPictureInPicureControllerPosition = .bottomLeft
    static let cornerRadius: CGFloat = 8
    static let animationDuration: TimeInterval = 0.3

    // MARK: HKPictureInPicureController
    var isPictureInPictureActive: Bool = false
    var pictureInPictureSize: CGSize = .init(width: 160, height: 90)
    var pictureInPictureMargin: CGFloat = HKPictureInPicureControllerImpl.margin
    var pictureInPicturePosition: HKPictureInPicureControllerPosition = HKPictureInPicureControllerImpl.position
    var pictureInPictureCornerRadius: CGFloat = HKPictureInPicureControllerImpl.cornerRadius
    var pictureInPictureAnimationDuration: TimeInterval = HKPictureInPicureControllerImpl.animationDuration

    private var window: UIWindow?
    private var parent: UIViewController?
    private let viewController: UIViewController
    private var currentPoint: CGPoint = .zero
    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanGestureRecognizer(_:)))

    init(_ viewController: UIViewController) {
        self.viewController = viewController
        self.parent = viewController.parent
    }

    func startPictureInPicture() {
        guard !isPictureInPictureActive else {
            return
        }
        toggleWindow()
        viewController.view.addGestureRecognizer(panGestureRecognizer)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        isPictureInPictureActive = true
    }

    func stopPictureInPicture() {
        guard isPictureInPictureActive else {
            return
        }
        toggleWindow()
        viewController.view.removeGestureRecognizer(panGestureRecognizer)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        isPictureInPictureActive = false
    }

    private func toggleWindow() {
        if window == nil {
            if let parent = parent {
                viewController.willMove(toParent: parent)
            }
            viewController.removeFromParent()
            viewController.view.removeFromSuperview()
            window = UIWindow(frame: .zero)
            window?.rootViewController = viewController
            window?.makeKeyAndVisible()
            if #available(iOSApplicationExtension 11.0, *) {
                transform(viewController.view.safeAreaInsets)
            } else {
                transform()
            }
            viewController.view.layer.cornerRadius = 8
        } else {
            window?.rootViewController = nil
            window = nil
            viewController.removeFromParent()
            parent?.addChild(viewController)
            parent?.view.addSubview(viewController.view)
            viewController.view.layer.cornerRadius = 0
            UIView.animate(withDuration: pictureInPictureAnimationDuration) { [weak self] in
                guard let self = self else {
                    return
                }
                self.viewController.view.frame = self.parent?.view.bounds ?? .zero
            }
        }
    }

    private func transform(_ insets: UIEdgeInsets = .zero) {
        UIView.animate(withDuration: pictureInPictureAnimationDuration) { [weak self] in
            guard let self = self else {
                return
            }
            let origin: CGPoint
            if self.currentPoint == .zero {
                origin = self.pictureInPicturePosition.CGPoint(self, insets: insets)
            } else {
                origin = self.currentPoint
            }
            self.window?.frame = .init(origin: origin, size: self.pictureInPictureSize)
        }
    }

    @objc
    private func orientationDidChange() {
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight, .portrait, .portraitUpsideDown:
            if #available(iOSApplicationExtension 11.0, *) {
                transform(viewController.view.safeAreaInsets)
            } else {
                transform()
            }
        default:
            break
        }
    }

    @objc
    private func didPanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        guard let window = window else {
            return
        }
        let point: CGPoint = sender.translation(in: viewController.view)
        window.center = CGPoint(x: window.center.x + point.x, y: window.center.y + point.y)
        currentPoint = window.frame.origin
        sender.setTranslation(.zero, in: viewController.view)
    }
}
