//
//  Localization.swift
//  MoshiMoshi
//
//  Runtime language switching without requiring app restart.
//  Usage: Text(L("key")) in any view that also has @ObservedObject private var lm = LocalizationManager.shared

import Foundation

// MARK: - Localization Manager

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "appLanguage")
        }
    }

    private init() {
        language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }

    func L(_ key: String) -> String {
        switch language {
        case "ja":      return jaStrings[key] ?? enStrings[key] ?? key
        case "zh-Hans": return zhStrings[key] ?? enStrings[key] ?? key
        default:        return enStrings[key] ?? key
        }
    }

    // MARK: - English

    private let enStrings: [String: String] = [
        // Navigation / Tabs
        "Home": "Home",
        "Discover": "Discover",
        "History": "History",
        "Profile": "Profile",

        // HomeView
        "Ready for your next reservation?": "Ready for your next reservation?",
        "Start a New Reservation": "Start a New Reservation",
        "Note: Restaurant availability varies. Agent will call to confirm.": "Note: Restaurant availability varies. Agent will call to confirm.",
        "Book Now": "Book Now",
        "ACTION REQUIRED": "ACTION REQUIRED",
        "Upcoming Events": "Upcoming Events",
        "No upcoming reservations": "No upcoming reservations",
        "Suggested Dining": "Suggested Dining",
        "Resolve Issue": "Resolve Issue",
        "View Options": "View Options",
        "Issue detected. Please review.": "Issue detected. Please review.",
        "Cancel": "Cancel",
        "Cancel reservation?": "Cancel reservation?",
        "Keep": "Keep",
        "Cancel reservation": "Cancel reservation",
        "This will mark the reservation as cancelled. You can still see it in History.": "This will mark the reservation as cancelled. You can still see it in History.",
        "Done": "Done",
        "Book Table": "Book Table",
        "Open Google Maps": "Open Google Maps",

        // HistoryView
        "Show past events": "Show past events",
        "Status": "Status",
        "All": "All",
        "No reservation history": "No reservation history",
        "No reservations match the current filters": "No reservations match the current filters",
        "View Details": "View Details",

        // DiscoverView
        "Search Results": "Search Results",
        "No results found": "No results found",
        "Offline Restaurant?": "Offline Restaurant?",
        "Can't find here? Give us the name and phone number, MoshiMoshi will handle the rest!": "Can't find here? Give us the name and phone number, MoshiMoshi will handle the rest!",
        "Manual Reservation": "Manual Reservation",
        "Featured Restaurants": "Featured Restaurants",
        "Search in %@...": "Search in %@...",

        // ProfileMenuView
        "User Name": "User Name",
        "Account": "Account",
        "Personal Information": "Personal Information",
        "Payment Methods": "Payment Methods",
        "Notifications": "Notifications",
        "Enabled": "Enabled",
        "Preferences": "Preferences",
        "Language": "Language",
        "Default Region": "Default Region",
        "Privacy & Security": "Privacy & Security",
        "Support": "Support",
        "Help Center": "Help Center",
        "App Settings": "App Settings",
        "Sign Out": "Sign Out",

        // AppSettingsView
        "System Default": "System Default",
        "Light Mode": "Light Mode",
        "Dark Mode": "Dark Mode",

        // ReservationFormView
        "New Reservation": "New Reservation",
        "RESTAURANT INFO": "RESTAURANT INFO",
        "Restaurant Name": "Restaurant Name",
        "Restaurant Phone": "Restaurant Phone",
        "RESERVATION DETAILS": "RESERVATION DETAILS",
        "Party Size": "Party Size",
        "YOUR CONTACT": "YOUR CONTACT",
        "Your Name": "Your Name",
        "Your Email": "Your Email",
        "Phone number": "Phone number",
        "SPECIAL REQUESTS": "SPECIAL REQUESTS",
        "Any allergies or special requests...": "Any allergies or special requests...",
        "Start AI Call": "Start AI Call",

        // ReservationTicketView
        "Price TBD": "Price TBD",
        "%d People": "%d People",

        // ProfileView
        "DEFAULT CONTACT INFO": "DEFAULT CONTACT INFO",
        "Your Default Name": "Your Default Name",
        "Save": "Save",
        "This information will be automatically filled in when you make a new reservation request.": "This information will be automatically filled in when you make a new reservation request.",

        // ReservationDetailView
        "Call History": "Call History",
        "Action Required": "Action Required",
        "The restaurant needs your response.": "The restaurant needs your response.",
    ]

    // MARK: - Japanese

    private let jaStrings: [String: String] = [
        // Navigation / Tabs
        "Home": "ホーム",
        "Discover": "探す",
        "History": "履歴",
        "Profile": "プロフィール",

        // HomeView
        "Ready for your next reservation?": "次の予約の準備はできていますか？",
        "Start a New Reservation": "新しい予約を始める",
        "Note: Restaurant availability varies. Agent will call to confirm.": "※空き状況は変動します。エージェントが確認のためお電話します。",
        "Book Now": "今すぐ予約",
        "ACTION REQUIRED": "対応が必要",
        "Upcoming Events": "近日の予約",
        "No upcoming reservations": "予約はありません",
        "Suggested Dining": "おすすめ",
        "Resolve Issue": "問題を解決",
        "View Options": "オプションを見る",
        "Issue detected. Please review.": "問題が検出されました。ご確認ください。",
        "Cancel": "キャンセル",
        "Cancel reservation?": "予約をキャンセルしますか？",
        "Keep": "保持する",
        "Cancel reservation": "予約をキャンセル",
        "This will mark the reservation as cancelled. You can still see it in History.": "予約をキャンセル済みにします。履歴でも確認できます。",
        "Done": "完了",
        "Book Table": "テーブルを予約",
        "Open Google Maps": "Googleマップで開く",

        // HistoryView
        "Show past events": "過去のイベントを表示",
        "Status": "ステータス",
        "All": "すべて",
        "No reservation history": "予約履歴はありません",
        "No reservations match the current filters": "現在のフィルターに合う予約はありません",
        "View Details": "詳細を見る",

        // DiscoverView
        "Search Results": "検索結果",
        "No results found": "結果が見つかりません",
        "Offline Restaurant?": "掲載されていないレストラン？",
        "Can't find here? Give us the name and phone number, MoshiMoshi will handle the rest!": "こちらで見つかりませんか？名前と電話番号を教えてください。",
        "Manual Reservation": "手動予約",
        "Featured Restaurants": "厳選レストラン",
        "Search in %@...": "%@で検索...",

        // ProfileMenuView
        "User Name": "ユーザー名",
        "Account": "アカウント",
        "Personal Information": "個人情報",
        "Payment Methods": "支払い方法",
        "Notifications": "通知",
        "Enabled": "有効",
        "Preferences": "環境設定",
        "Language": "言語",
        "Default Region": "デフォルト地域",
        "Privacy & Security": "プライバシーとセキュリティ",
        "Support": "サポート",
        "Help Center": "ヘルプセンター",
        "App Settings": "アプリ設定",
        "Sign Out": "サインアウト",

        // AppSettingsView
        "System Default": "システムデフォルト",
        "Light Mode": "ライトモード",
        "Dark Mode": "ダークモード",

        // ReservationFormView
        "New Reservation": "新しい予約",
        "RESTAURANT INFO": "レストラン情報",
        "Restaurant Name": "レストラン名",
        "Restaurant Phone": "電話番号",
        "RESERVATION DETAILS": "予約の詳細",
        "Party Size": "人数",
        "YOUR CONTACT": "連絡先",
        "Your Name": "お名前",
        "Your Email": "メールアドレス",
        "Phone number": "電話番号",
        "SPECIAL REQUESTS": "特別なリクエスト",
        "Any allergies or special requests...": "アレルギーや特別なリクエストがあれば...",
        "Start AI Call": "AIに電話させる",

        // ReservationTicketView
        "Price TBD": "価格未定",
        "%d People": "%d 人",

        // ProfileView
        "DEFAULT CONTACT INFO": "デフォルト連絡先情報",
        "Your Default Name": "デフォルトのお名前",
        "Save": "保存",
        "This information will be automatically filled in when you make a new reservation request.": "この情報は予約リクエスト時に自動的に入力されます。",

        // ReservationDetailView
        "Call History": "通話履歴",
        "Action Required": "対応が必要",
        "The restaurant needs your response.": "レストランからの返答が必要です。",
    ]

    // MARK: - Chinese Simplified

    private let zhStrings: [String: String] = [
        // Navigation / Tabs
        "Home": "首页",
        "Discover": "发现",
        "History": "历史",
        "Profile": "我的",

        // HomeView
        "Ready for your next reservation?": "准备好您的下一次预约了吗？",
        "Start a New Reservation": "开始新预约",
        "Note: Restaurant availability varies. Agent will call to confirm.": "注意：餐厅可用性可能变化。代理将致电确认。",
        "Book Now": "立即预订",
        "ACTION REQUIRED": "需要处理",
        "Upcoming Events": "即将到来的活动",
        "No upcoming reservations": "暂无预约",
        "Suggested Dining": "推荐餐厅",
        "Resolve Issue": "解决问题",
        "View Options": "查看选项",
        "Issue detected. Please review.": "发现问题，请查看。",
        "Cancel": "取消",
        "Cancel reservation?": "取消预约？",
        "Keep": "保留",
        "Cancel reservation": "取消预约",
        "This will mark the reservation as cancelled. You can still see it in History.": "这将把预约标记为已取消，您仍可在历史记录中查看。",
        "Done": "完成",
        "Book Table": "预订桌位",
        "Open Google Maps": "在Google地图中打开",

        // HistoryView
        "Show past events": "显示过去的活动",
        "Status": "状态",
        "All": "全部",
        "No reservation history": "暂无预约历史",
        "No reservations match the current filters": "没有符合当前筛选的预约",
        "View Details": "查看详情",

        // DiscoverView
        "Search Results": "搜索结果",
        "No results found": "未找到结果",
        "Offline Restaurant?": "找不到餐厅？",
        "Can't find here? Give us the name and phone number, MoshiMoshi will handle the rest!": "找不到？提供餐厅名称和电话号码，MoshiMoshi将处理其余事宜！",
        "Manual Reservation": "手动预约",
        "Featured Restaurants": "精选餐厅",
        "Search in %@...": "在%@中搜索...",

        // ProfileMenuView
        "User Name": "用户名",
        "Account": "账户",
        "Personal Information": "个人信息",
        "Payment Methods": "支付方式",
        "Notifications": "通知",
        "Enabled": "已启用",
        "Preferences": "偏好设置",
        "Language": "语言",
        "Default Region": "默认地区",
        "Privacy & Security": "隐私与安全",
        "Support": "支持",
        "Help Center": "帮助中心",
        "App Settings": "应用设置",
        "Sign Out": "退出登录",

        // AppSettingsView
        "System Default": "跟随系统",
        "Light Mode": "浅色模式",
        "Dark Mode": "深色模式",

        // ReservationFormView
        "New Reservation": "新预约",
        "RESTAURANT INFO": "餐厅信息",
        "Restaurant Name": "餐厅名称",
        "Restaurant Phone": "餐厅电话",
        "RESERVATION DETAILS": "预约详情",
        "Party Size": "人数",
        "YOUR CONTACT": "您的联系方式",
        "Your Name": "您的姓名",
        "Your Email": "您的邮箱",
        "Phone number": "电话号码",
        "SPECIAL REQUESTS": "特殊要求",
        "Any allergies or special requests...": "任何过敏或特殊要求...",
        "Start AI Call": "开始AI通话",

        // ReservationTicketView
        "Price TBD": "价格待定",
        "%d People": "%d 人",

        // ProfileView
        "DEFAULT CONTACT INFO": "默认联系信息",
        "Your Default Name": "您的默认姓名",
        "Save": "保存",
        "This information will be automatically filled in when you make a new reservation request.": "此信息将在您提出新预约请求时自动填写。",

        // ReservationDetailView
        "Call History": "通话记录",
        "Action Required": "需要处理",
        "The restaurant needs your response.": "餐厅需要您的回复。",
    ]
}

// MARK: - Global helper

func L(_ key: String) -> String {
    LocalizationManager.shared.L(key)
}
