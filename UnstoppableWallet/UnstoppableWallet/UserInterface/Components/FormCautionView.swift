import UIKit
import ThemeKit
import SnapKit

class FormCautionView: UIView {
    private let padding = UIEdgeInsets(top: .margin8, left: .margin24, bottom: 0, right: .margin24)
    private let font: UIFont = .caption

    private let label = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(padding)
        }

        label.font = font
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FormCautionView {

    func set(caution: Caution?) {
        if let caution = caution {
            label.text = caution.text
            label.textColor = caution.type.color
        } else {
            label.text = nil
        }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        guard let text = label.text, !text.isEmpty else {
            return 0
        }

        let textWidth = containerWidth - padding.width
        let textHeight = text.height(forContainerWidth: textWidth, font: font)

        return textHeight + padding.height
    }

}
