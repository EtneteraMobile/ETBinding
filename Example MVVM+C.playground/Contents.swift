import UIKit
import PlaygroundSupport
import ETBinding

//: # MVVM + Coordinators

typealias Face = String

// MARK: - Coordinator

class Coordinator {
    private let container = Container(isRotationEnabled: false)
    private var controllers: [UIViewController] = []

    func start() {
        let faceSelectionVM = FaceSelectionVM()

        let faceSelectionVC = FaceSelectionVC(vm: faceSelectionVM)
        faceSelectionVC.didSelectFace.observe(owner: self) { [unowned self] face in
            self.showDetail(face)
        }

        showVC(faceSelectionVC)
    }

    private func showDetail(_ face: Face) {
        let faceDetailVM = FaceDetailVM()
        faceDetailVM.face.data = face

        let faceDetailVC = FaceDetailVC(vm: faceDetailVM)
        faceDetailVC.close.observeSingleEvent(owner: self) { [unowned self] in
            self.showList()
        }

        showVC(faceDetailVC)
    }

    private func showList() {
        self.container.content.addSubview(controllers.first!.view)
        self.controllers.removeLast()
    }

    private func showVC(_ vc: UIViewController) {
        vc.view.frame = container.content.bounds
        controllers.append(vc)
        container.content.addSubview(vc.view)
    }
}

// MARK: - Face selection

protocol FaceSelectionVMType {
    var faces: LiveData<[Face]> { get }
    func fetch()
}

class FaceSelectionVM: FaceSelectionVMType {
    let faces: LiveData<[Face]> = LiveData()

    func fetch() {
        var all = ["cislo", "hudys", "jakub", "jirka", "kien", "kori", "mirek", "petr"]
        let count = arc4random_uniform(UInt32(all.count - 1)) + 1
        var rVal: [Face] = []
        for _ in 0..<count {
            rVal.append(all.remove(at: Int(arc4random_uniform(UInt32(all.count)))))
        }
        faces.data = rVal
    }
}

class FaceSelectionVC: UIViewController {
    let didSelectFace: FutureEvent<Face> = FutureEvent()

    private let vm: FaceSelectionVMType
    private var clickHandlers: [ClickHandler] = []

    init(vm: FaceSelectionVMType) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view

        vm.faces.observe(owner: self) { [unowned self] faces in
            self.view.subviews.forEach {
                $0.removeFromSuperview()
            }
            self.clickHandlers = []
            faces?.enumerated().forEach { idx, face in
                self.makeButton(idx, face)
            }
        }
        vm.fetch()
    }

    private func makeButton(_ idx: Int, _ face: Face) {
        let size: CGFloat = 60
        let faceButton = UIButton()
        faceButton.setImage(UIImage(named: face), for: .normal)
        faceButton.frame = CGRect(x: 160, y: 10 + CGFloat(idx) * (size + 10), width: size, height: size)
        faceButton.imageView?.contentMode = .scaleAspectFit
        self.view.addSubview(faceButton)

        let pressFace = ClickHandler(onClick: { [unowned self] in
            self.didSelectFace.trigger(face)
        })
        clickHandlers.append(pressFace)
        faceButton.addTarget(pressFace, action: #selector(ClickHandler.click), for: .touchUpInside)

        let pressOutOfFace = ClickHandler(onClick: { [unowned self] in
            self.vm.fetch()
        })
        clickHandlers.append(pressOutOfFace)
        faceButton.addTarget(pressOutOfFace, action: #selector(ClickHandler.click), for: .touchUpOutside)
    }
}

// MARK: - Face detail

protocol FaceDetailVMForVCType {
    var face: LiveData<Face> { get }
}

class FaceDetailVM: FaceDetailVMForVCType {
    let face: LiveData<Face> = LiveData()
}

class FaceDetailVC: UIViewController {
    let close: SingleEvent<Void> = SingleEvent()
    private let vm: FaceDetailVMForVCType
    private var clickHandler: ClickHandler!

    init(vm: FaceDetailVMForVCType) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let view = UIButton()
        view.backgroundColor = .white
        self.view = view

        vm.face.observe(owner: self) { face in
            view.setImage(UIImage(named: face!), for: .normal)
        }
        vm.face.dispatch()

        clickHandler = ClickHandler(onClick: { [unowned self] in
            self.close.trigger()
        })

        view.addTarget(clickHandler, action: #selector(ClickHandler.click), for: .touchUpInside)
    }
}

var coord: Coordinator? = Coordinator()
coord?.start()
