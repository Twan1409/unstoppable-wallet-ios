import RxSwift
import RxCocoa
import UniswapKit

class SwapSlippageViewModel {
    private let disposeBag = DisposeBag()

    private let valueRelay = BehaviorRelay<String?>(value: nil)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    private let service: SwapTradeOptionsService
    private let decimalParser: IAmountDecimalParser

    public init(service: SwapTradeOptionsService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.update(errors: $0) }
    }

    private func update(errors: [Error]) {
        let error = errors.first(where: {
            if case .invalidSlippage = $0 as? SwapTradeOptionsService.TradeOptionsError {
                return true
            }
            return false
        })

        cautionRelay.accept(error.map { Caution(text: $0.smartDescription, type: .error)})
    }

}

extension SwapSlippageViewModel {

    var placeholder: String {
        TradeOptions.defaultSlippage.description
    }

    var initialValue: String? {
        guard case let .valid(tradeOptions) = service.state, tradeOptions.allowedSlippage != TradeOptions.defaultSlippage else {
            return nil
        }

        return tradeOptions.allowedSlippage.description
    }

    var shortcuts: [InputShortcut] {
        let bounds = service.recommendedSlippageBounds

        return [
            InputShortcut(title: "\(bounds.lowerBound.description)%", value: bounds.lowerBound.description),
            InputShortcut(title: "\(bounds.upperBound.description)%", value: bounds.upperBound.description),
        ]
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func onChange(text: String?) {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            service.slippage = TradeOptions.defaultSlippage
            return
        }

        service.slippage = value
    }

    func isValid(text: String) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        return amount.decimalCount <= 2
    }

}
