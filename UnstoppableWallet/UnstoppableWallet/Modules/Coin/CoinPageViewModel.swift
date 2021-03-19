import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import CoinKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let returnOfInvestmentsViewItemsFactory = ReturnOfInvestmentsViewItemsFactory()
    private let marketViewItemFactory = MarketViewItemFactory()
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)

    init(service: CoinPageService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinMarketInfo>) {
        loadingRelay.accept(state.isLoading)

        let viewItem = state.data.map { info in
            ViewItem(
                    returnOfInvestmentsViewItems: returnOfInvestmentsViewItemsFactory.viewItems(info: info, diffCoinCodes: service.diffCoinCodes, currentCoinCode: service.coinCode, timePeriods: CoinPageService.timePeriods),
                    tickers: info.tickers,
                    fundCategories: info.meta.fundCategories,
                    categories: categories(info: info),
                    contractInfo: contractInfo(info: info),
                    guideUrl: service.guideUrl,
                    links: links(info: info),
                    marketInfo: marketInfo(rate: info.rate, marketCap: info.marketCap, volume24h: info.volume24h, circulatingSupply: info.circulatingSupply, totalSupply: info.totalSupply),
                    description: info.meta.description
            )
        }

        viewItemRelay.accept(viewItem)
    }

    private func links(info: CoinMarketInfo) -> [Link] {
        let linkMap = info.meta.links
        let linkTypes: [LinkType] = [.website, .whitepaper, .reddit, .twitter, .telegram, .github]

        return linkTypes.compactMap { linkType in
            guard let url = linkMap[linkType], !url.isEmpty else {
                return nil
            }

            return Link(type: linkType, url: url)
        }
    }

    private func categories(info: CoinMarketInfo) -> [String]? {
        let categories = info.meta.categories
        return categories.isEmpty ? nil : categories
    }

    private func contractInfo(info: CoinMarketInfo) -> ContractInfo? {
        switch info.data.coinType {
        case .erc20(let address): return ContractInfo(title: "coin_page.contract".localized("ETH"), value: address)
        case .bep20(let address): return ContractInfo(title: "coin_page.contract".localized("BSC"), value: address)
        case .bep2(let symbol): return ContractInfo(title: "coin_page.bep2_symbol".localized, value: symbol)
        default: return nil
        }
    }

    private func marketInfo(rate: Decimal?, marketCap: Decimal?, volume24h: Decimal?, circulatingSupply: Decimal?, totalSupply: Decimal?) -> MarketInfo {
        marketViewItemFactory.viewItem(
                rate: rate,
                marketCap: marketCap,
                volume24h: volume24h,
                circulatingSupply: circulatingSupply,
                totalSupply: totalSupply,
                currency: service.currency,
                coinCode: service.coinCode
        )
    }

}

extension CoinPageViewModel {

    var title: String {
        service.coinCode
    }

    var subtitle: String {
        service.coinTitle
    }

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var coinCode: String {
        service.coinCode
    }

}

extension CoinPageViewModel {

    struct ViewItem {
        let returnOfInvestmentsViewItems: [[ReturnOfInvestmentsViewItem]]
        let tickers: [MarketTicker]
        let fundCategories: [CoinFundCategory]
        let categories: [String]?
        let contractInfo: ContractInfo?
        let guideUrl: URL?
        let links: [Link]
        let marketInfo: MarketInfo
        let description: String
    }

    struct ContractInfo {
        let title: String
        let value: String
    }

    enum ReturnOfInvestmentsViewItem {
        case title(String)
        case subtitle(String)
        case content(String)
        case value(Decimal?)

        var font: UIFont? {
            switch self {
            case .title: return .subhead1
            case .subtitle: return .caption
            case .content: return .caption
            case .value: return nil
            }
        }

        var color: UIColor? {
            switch self {
            case .title: return .themeOz
            case .subtitle: return .themeBran
            case .content: return .themeGray
            case .value: return nil
            }
        }

        var backgroundColor: UIColor? {
            switch self {
            case .title, .subtitle: return .themeLawrence
            case .content, .value: return .themeBlake
            }
        }

    }

    struct Link {
        let type: LinkType
        let url: String

        var icon: UIImage? {
            switch type {
            case .website: return UIImage(named: "globe_20")
            case .whitepaper: return UIImage(named: "academy_1_20") // todo
            case .reddit: return UIImage(named: "reddit_20")
            case .twitter: return UIImage(named: "twitter_20")
            case .telegram: return UIImage(named: "telegram_20")
            case .github: return UIImage(named: "github_20")
            default: return nil
            }
        }

        var title: String {
            switch type {
            case .website: return "coin_page.website".localized
            case .whitepaper: return "coin_page.whitepaper".localized
            case .reddit: return "Reddit"
            case .twitter: return "Twitter"
            case .telegram: return "Telegram"
            case .github: return "Github"
            default: return ""
            }
        }
    }

    struct MarketInfo {
        public let marketCap: String?
        public let volume24h: String?
        public let circulatingSupply: String?
        public let totalSupply: String?
        public let dillutedMarketCap: String?
    }

}
