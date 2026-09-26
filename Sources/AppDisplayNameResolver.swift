import Foundation
import AppKit

/// 进程与应用名称多语言动态解析器
/// 支持系统核心组件高精度映射与第三方应用 Bundle InfoPlist.strings 动态探测
public final class AppDisplayNameResolver {
    public static let shared = AppDisplayNameResolver()
    private init() {}

    private var cache: [String: String] = [:]
    private let lock = NSLock()

    // 1. 系统核心组件与 macOS 原生内置应用的高精度多语言映射字典
    private let systemAppLocalizations: [String: [AppLanguage: String]] = [
        "com.apple.finder": [
            .en: "Finder", .zhHans: "访达", .zhHant: "訪達", .ja: "Finder", .ko: "Finder",
            .fr: "Finder", .de: "Finder", .es: "Finder", .it: "Finder", .ru: "Finder",
            .nl: "Finder", .pl: "Finder", .tr: "Finder", .ar: "Finder", .th: "Finder",
            .vi: "Finder", .id: "Finder", .sv: "Finder", .da: "Finder", .nb: "Finder",
            .fi: "Finder", .cs: "Finder", .uk: "Finder"
        ],
        "com.apple.dock": [
            .en: "Dock", .zhHans: "程序坞", .zhHant: "Dock", .ja: "Dock", .ko: "Dock",
            .fr: "Dock", .de: "Dock", .es: "Dock", .it: "Dock", .ru: "Dock",
            .ar: "Dock"
        ],
        "com.apple.controlcenter": [
            .en: "Control Center", .zhHans: "控制中心", .zhHant: "控制中心",
            .ja: "コントロールセンター", .ko: "제어 센터", .fr: "Centre de contrôle",
            .de: "Kontrollzentrum", .es: "Centro de control", .it: "Centro di Controllo",
            .ru: "Пункт управления", .nl: "Bedieningspaneel", .pl: "Centrum sterowania",
            .tr: "Denetim Merkezi", .ar: "مركز التحكم", .th: "ศูนย์ควบคุม",
            .vi: "Trung tâm điều khiển", .id: "Pusat Kontrol", .sv: "Kontrollcenter",
            .da: "Kontrolcenter", .nb: "Kontrollsenter", .fi: "Ohjauskeskus",
            .cs: "Ovládací centrum", .uk: "Центр керування"
        ],
        "com.apple.notificationcenterui": [
            .en: "Notification Center", .zhHans: "通知中心", .zhHant: "通知中心",
            .ja: "通知センター", .ko: "알림 센터", .fr: "Centre de notifications",
            .de: "Mitteilungszentrale", .es: "Centro de notificaciones", .it: "Centro Notifiche",
            .ru: "Центр уведомлений", .nl: "Berichtencentrum", .pl: "Centrum powiadomień",
            .tr: "Bildirim Merkezi", .ar: "مركز الإشعارات", .th: "ศูนย์การแจ้งเตือน",
            .vi: "Trung tâm thông báo", .id: "Pusat Pemberitahuan", .sv: "Notiscenter",
            .da: "Meddelelsescenter", .nb: "Varslingssenter", .fi: "Ilmoituskeskus",
            .cs: "Oznamovací centrum", .uk: "Центр сповіщень"
        ],
        "com.apple.ActivityMonitor": [
            .en: "Activity Monitor", .zhHans: "活动监视器", .zhHant: "活動監視器",
            .ja: "アクティビティモニタ", .ko: "활성 상태 보기", .fr: "Moniteur d’activité",
            .de: "Aktivitätsanzeige", .es: "Monitor de Actividad", .it: "Monitoraggio Attività",
            .ru: "Мониторинг системы", .nl: "Activiteitenweergave", .pl: "Monitor aktywności",
            .tr: "Etkinlik Monitörü", .ar: "مراقب النشاط", .th: "ตัวตรวจสอบกิจกรรม",
            .vi: "Giám sát hoạt động", .id: "Monitor Aktivitas", .sv: "Aktivitetskontroll",
            .da: "Aktivitetsovervågning", .nb: "Aktivitetsmonitor", .fi: "Järjestelmän valvonta",
            .cs: "Monitor aktivity", .uk: "Монітор активності"
        ],
        "com.apple.systempreferences": [
            .en: "System Settings", .zhHans: "系统设置", .zhHant: "系統設定",
            .ja: "システム設定", .ko: "시스템 설정", .fr: "Réglages Système",
            .de: "Systemeinstellungen", .es: "Ajustes del Sistema", .it: "Impostazioni di Sistema",
            .ru: "Системные настройки", .nl: "Systeeminstellingen", .pl: "Ustawienia systemowe",
            .tr: "Sistem Ayarları", .ar: "إعدادات النظام", .th: "การตั้งค่าระบบ",
            .vi: "Cài đặt hệ thống", .id: "Pengaturan Sistem", .sv: "Systeminställningar",
            .da: "Systemindstillinger", .nb: "Systeminnstillinger", .fi: "Järjestelmäasetukset",
            .cs: "Nastavení systému", .uk: "Системні параметри"
        ],
        "com.apple.iCal": [
            .en: "Calendar", .zhHans: "日历", .zhHant: "行事曆",
            .ja: "カレンダー", .ko: "캘린더", .fr: "Calendrier",
            .de: "Kalender", .es: "Calendario", .it: "Calendario",
            .ru: "Календарь", .nl: "Agenda", .pl: "Kalendarz",
            .tr: "Takvim", .ar: "التقويم", .th: "ปฏิทิน",
            .vi: "Lịch", .id: "Kalender", .sv: "Kalender",
            .da: "Kalender", .nb: "Kalender", .fi: "Kalenteri",
            .cs: "Kalendář", .uk: "Календар"
        ],
        "com.apple.Safari": [
            .en: "Safari", .zhHans: "Safari 浏览器", .zhHant: "Safari 瀏覽器",
            .ja: "Safari", .ko: "Safari", .fr: "Safari",
            .de: "Safari", .es: "Safari", .it: "Safari",
            .ru: "Safari", .ar: "Safari"
        ],
        "com.apple.Terminal": [
            .en: "Terminal", .zhHans: "终端", .zhHant: "終端機",
            .ja: "ターミナル", .ko: "터미널", .fr: "Terminal",
            .de: "Terminal", .es: "Terminal", .it: "Terminal",
            .ru: "Терминал", .nl: "Terminal", .pl: "Terminal",
            .tr: "Terminal", .ar: "Terminal", .th: "เทอร์มินัล",
            .vi: "Terminal", .id: "Terminal", .sv: "Terminal",
            .da: "Terminal", .nb: "Terminal", .fi: "Pääte",
            .cs: "Terminál", .uk: "Термінал"
        ],
        "com.apple.Preview": [
            .en: "Preview", .zhHans: "预览", .zhHant: "預覽程式",
            .ja: "プレビュー", .ko: "미리보기", .fr: "Aperçu",
            .de: "Vorschau", .es: "Vista Previa", .it: "Anteprima",
            .ru: "Просмотр", .nl: "Voorvertoning", .pl: "Podgląd",
            .tr: "Önizleme", .ar: "معاينة", .th: "การแสดงตัวอย่าง",
            .vi: "Xem trước", .id: "Pratinjau", .sv: "Förhandsvisning",
            .da: "Billedfremviser", .nb: "Forhåndsvisning", .fi: "Esikatselu",
            .cs: "Náhled", .uk: "Огляд"
        ],
        "com.apple.Music": [
            .en: "Music", .zhHans: "音乐", .zhHant: "音樂",
            .ja: "ミュージック", .ko: "음악", .fr: "Musique",
            .de: "Musik", .es: "Música", .it: "Musica",
            .ru: "Музыка", .nl: "Muziek", .pl: "Muzyka",
            .tr: "Müzik", .ar: "الموسيقى", .th: "เพลง",
            .vi: "Nhạc", .id: "Musik", .sv: "Musik",
            .da: "Musik", .nb: "Musikk", .fi: "Musiikki",
            .cs: "Hudba", .uk: "Музика"
        ],
        "com.apple.Photos": [
            .en: "Photos", .zhHans: "照片", .zhHant: "照片",
            .ja: "写真", .ko: "사진", .fr: "Photos",
            .de: "Fotos", .es: "Fotos", .it: "Foto",
            .ru: "Фото", .nl: "Foto's", .pl: "Zdjęcia",
            .tr: "Fotoğraflar", .ar: "الصور", .th: "รูปภาพ",
            .vi: "Ảnh", .id: "Foto", .sv: "Bilder",
            .da: "Fotos", .nb: "Bilder", .fi: "Kuvat",
            .cs: "Fotky", .uk: "Фотографії"
        ],
        "com.apple.Notes": [
            .en: "Notes", .zhHans: "备忘录", .zhHant: "備忘錄",
            .ja: "メモ", .ko: "메모", .fr: "Notes",
            .de: "Notizen", .es: "Notas", .it: "Note",
            .ru: "Заметки", .nl: "Notities", .pl: "Notatki",
            .tr: "Notlar", .ar: "ملاحظات", .th: "โน้ต",
            .vi: "Ghi chú", .id: "Catatan", .sv: "Anteckningar",
            .da: "Noter", .nb: "Notater", .fi: "Muistiinpanot",
            .cs: "Poznámky", .uk: "Нотатки"
        ],
        "com.apple.Reminders": [
            .en: "Reminders", .zhHans: "提醒事项", .zhHant: "提醒事項",
            .ja: "リマインダー", .ko: "미리 알림", .fr: "Rappels",
            .de: "Erinnerungen", .es: "Recordatorios", .it: "Promemoria",
            .ru: "Напоминания", .nl: "Herinneringen", .pl: "Przypomnienia",
            .tr: "Anımsatıcılar", .ar: "تذكيرات", .th: "เตือนความจำ",
            .vi: "Lời nhắc", .id: "Pengingat", .sv: "Påminnelser",
            .da: "Påmindelser", .nb: "Påminnelser", .fi: "Muistutukset",
            .cs: "Připomínky", .uk: "Нагадування"
        ],
        "com.apple.calculator": [
            .en: "Calculator", .zhHans: "计算器", .zhHant: "計算機",
            .ja: "計算機", .ko: "계산기", .fr: "Calculette",
            .de: "Rechner", .es: "Calculadora", .it: "Calcolatrice",
            .ru: "Калькулятор", .nl: "Rekenmachine", .pl: "Kalkulator",
            .tr: "Hesap Makinesi", .ar: "آلة حاسبة", .th: "เครื่องคิดเลข",
            .vi: "Máy tính", .id: "Kalkulator", .sv: "Kalkylator",
            .da: "Lommeregner", .nb: "Kalkulator", .fi: "Laskin",
            .cs: "Kalkulačka", .uk: "Калькулятор"
        ],
        "com.apple.TextEdit": [
            .en: "TextEdit", .zhHans: "文本编辑", .zhHant: "文字編輯",
            .ja: "テキストエディット", .ko: "텍스트 편집기", .fr: "TextEdit",
            .de: "TextEdit", .es: "TextEdit", .it: "TextEdit",
            .ru: "TextEdit", .nl: "Teksteditor", .pl: "TextEdit",
            .tr: "Metin Düzenleyici", .ar: "محرر النصوص", .th: "TextEdit",
            .vi: "TextEdit", .id: "TextEdit", .sv: "Textredigerare",
            .da: "TextEdit", .nb: "TextEdit", .fi: "Teksturi",
            .cs: "TextEdit", .uk: "TextEdit"
        ],
        "com.apple.AppStore": [
            .en: "App Store", .zhHans: "App Store", .zhHant: "App Store",
            .ja: "App Store", .ko: "App Store", .fr: "App Store",
            .de: "App Store", .es: "App Store", .it: "App Store",
            .ru: "App Store", .ar: "App Store"
        ],
        "com.apple.MobileSMS": [
            .en: "Messages", .zhHans: "信息", .zhHant: "訊息",
            .ja: "メッセージ", .ko: "메시지", .fr: "Messages",
            .de: "Nachrichten", .es: "Mensajes", .it: "Messaggi",
            .ru: "Сообщения", .nl: "Berichten", .pl: "Wiadomości",
            .tr: "Mesajlar", .ar: "الرسائل", .th: "ข้อความ",
            .vi: "Tin nhắn", .id: "Pesan", .sv: "Meddelanden",
            .da: "Beskeder", .nb: "Meldinger", .fi: "Viestit",
            .cs: "Zprávy", .uk: "Повідомлення"
        ],
        "com.apple.mail": [
            .en: "Mail", .zhHans: "邮件", .zhHant: "郵件",
            .ja: "メール", .ko: "Mail", .fr: "Mail",
            .de: "Mail", .es: "Mail", .it: "Mail",
            .ru: "Почта", .nl: "Mail", .pl: "Poczta",
            .tr: "Mail", .ar: "البريد", .th: "เมล",
            .vi: "Mail", .id: "Mail", .sv: "Brev",
            .da: "Mail", .nb: "Mail", .fi: "Mail",
            .cs: "Mail", .uk: "Пошта"
        ],
        "com.apple.Maps": [
            .en: "Maps", .zhHans: "地图", .zhHant: "地圖",
            .ja: "マップ", .ko: "지도", .fr: "Plans",
            .de: "Karten", .es: "Mapas", .it: "Mappe",
            .ru: "Карты", .nl: "Kaarten", .pl: "Mapy",
            .tr: "Harita", .ar: "الخرائط", .th: "แผนที่",
            .vi: "Bản đồ", .id: "Peta", .sv: "Kartor",
            .da: "Kort", .nb: "Kart", .fi: "Kartat",
            .cs: "Mapy", .uk: "Карти"
        ],
        "com.apple.FaceTime": [
            .en: "FaceTime", .zhHans: "FaceTime 通话", .zhHant: "FaceTime 通話",
            .ja: "FaceTime", .ko: "FaceTime", .fr: "FaceTime",
            .de: "FaceTime", .es: "FaceTime", .it: "FaceTime",
            .ru: "FaceTime", .ar: "FaceTime"
        ],
        "com.apple.clock": [
            .en: "Clock", .zhHans: "时钟", .zhHant: "時鐘",
            .ja: "時計", .ko: "시계", .fr: "Horloge",
            .de: "Uhr", .es: "Reloj", .it: "Orologio",
            .ru: "Часы", .nl: "Klok", .pl: "Zegar",
            .tr: "Saat", .ar: "الساعة", .th: "นาฬิกา",
            .vi: "Đồng hồ", .id: "Jam", .sv: "Klocka",
            .da: "Ur", .nb: "Klokke", .fi: "Kello",
            .cs: "Hodiny", .uk: "Годинник"
        ],
        "com.apple.shortcuts": [
            .en: "Shortcuts", .zhHans: "快捷指令", .zhHant: "捷徑",
            .ja: "ショートカット", .ko: "단축어", .fr: "Raccourcis",
            .de: "Kurzbefehle", .es: "Atajos", .it: "Comandi Rapidi",
            .ru: "Быстрые команды", .nl: "Opdrachten", .pl: "Skróty",
            .tr: "Kestirmeler", .ar: "الاختصارات", .th: "คำสั่งลัด",
            .vi: "Phím tắt", .id: "Pintasan", .sv: "Genvägar",
            .da: "Genveje", .nb: "Snarveier", .fi: "Pikakomennot",
            .cs: "Zkratky", .uk: "Команди"
        ],
        "com.apple.weather": [
            .en: "Weather", .zhHans: "天气", .zhHant: "天氣",
            .ja: "天気", .ko: "날씨", .fr: "Météo",
            .de: "Wetter", .es: "Tiempo", .it: "Meteo",
            .ru: "Погода", .nl: "Weer", .pl: "Pogoda",
            .tr: "Hava Durumu", .ar: "الطقس", .th: "สภาพอากาศ",
            .vi: "Thời tiết", .id: "Cuaca", .sv: "Väder",
            .da: "Vejr", .nb: "Vær", .fi: "Sää",
            .cs: "Počasí", .uk: "Погода"
        ],
        "com.apple.stocks": [
            .en: "Stocks", .zhHans: "股市", .zhHant: "股市",
            .ja: "株価", .ko: "주식", .fr: "Bourse",
            .de: "Aktien", .es: "Bolsa", .it: "Borsa",
            .ru: "Акции", .nl: "Aandelen", .pl: "Giełda",
            .tr: "Borsa", .ar: "الأسهم", .th: "หุ้น",
            .vi: "Chứng khoán", .id: "Saham", .sv: "Aktier",
            .da: "Værdipapirer", .nb: "Aksjer", .fi: "Pörssi",
            .cs: "Akcie", .uk: "Біржі"
        ],
        "com.apple.VoiceMemos": [
            .en: "Voice Memos", .zhHans: "语音备忘录", .zhHant: "語音備忘錄",
            .ja: "ボイスメモ", .ko: "음성 메모", .fr: "Dictaphone",
            .de: "Sprachmemos", .es: "Notas de Voz", .it: "Memo Vocali",
            .ru: "Диктофон", .nl: "Dictafoon", .pl: "Dyktafon",
            .tr: "Sesli Düşler", .ar: "المذكرات الصوتية", .th: "เสียงบันทึก",
            .vi: "Ghi âm", .id: "Memo Suara", .sv: "Röstmemon",
            .da: "Memoer", .nb: "Taleopptak", .fi: "Sanelut",
            .cs: "Diktafon", .uk: "Диктофон"
        ],
        "com.apple.podcasts": [
            .en: "Podcasts", .zhHans: "播客", .zhHant: "播客",
            .ja: "ポッドキャスト", .ko: "팟캐스트", .fr: "Podcasts",
            .de: "Podcasts", .es: "Podcasts", .it: "Podcast",
            .ru: "Подкасты", .nl: "Podcasts", .pl: "Podcasty",
            .tr: "Podcast'ler", .ar: "البودكاست", .th: "พ็อดคาสท์",
            .vi: "Podcast", .id: "Podcast", .sv: "Podcaster",
            .da: "Podcasts", .nb: "Podkaster", .fi: "Podcastit",
            .cs: "Podcasty", .uk: "Подкасти"
        ],
        "com.apple.iBooksX": [
            .en: "Books", .zhHans: "图书", .zhHant: "書籍",
            .ja: "ブック", .ko: "도서", .fr: "Livres",
            .de: "Bücher", .es: "Libros", .it: "Libri",
            .ru: "Книги", .nl: "Boeken", .pl: "Książki",
            .tr: "Kitaplar", .ar: "الكتب", .th: "หนังสือ",
            .vi: "Sách", .id: "Buku", .sv: "Böcker",
            .da: "Bøger", .nb: "Bøker", .fi: "Kirjat",
            .cs: "Knihy", .uk: "Книги"
        ],
        "com.apple.AddressBook": [
            .en: "Contacts", .zhHans: "通讯录", .zhHant: "聯絡資訊",
            .ja: "連絡先", .ko: "연락처", .fr: "Contacts",
            .de: "Kontakte", .es: "Contactos", .it: "Contatti",
            .ru: "Контакты", .nl: "Contacten", .pl: "Kontakty",
            .tr: "Kişiler", .ar: "جهات الاتصال", .th: "รายชื่อ",
            .vi: "Danh bạ", .id: "Kontak", .sv: "Kontakter",
            .da: "Kontakter", .nb: "Kontakter", .fi: "Yhteystiedot",
            .cs: "Kontakty", .uk: "Контакти"
        ],
        "com.apple.findmy": [
            .en: "Find My", .zhHans: "查找", .zhHant: "尋找",
            .ja: "探す", .ko: "나의 찾기", .fr: "Localiser",
            .de: "Wo ist?", .es: "Buscar", .it: "Dov'è",
            .ru: "Локатор", .nl: "Zoek mijn", .pl: "Lokalizator",
            .tr: "Bul", .ar: "تحديد الموقع", .th: "ค้นหาของฉัน",
            .vi: "Tìm", .id: "Lacak", .sv: "Hitta",
            .da: "Find", .nb: "Hvor er?", .fi: "Etsi",
            .cs: "Najít", .uk: "Локатор"
        ],
        "com.apple.Passwords": [
            .en: "Passwords", .zhHans: "密码", .zhHant: "密碼",
            .ja: "パスワード", .ko: "암호", .fr: "Mots de passe",
            .de: "Passwörter", .es: "Contraseñas", .it: "Password",
            .ru: "Пароли", .nl: "Wachtwoorden", .pl: "Hasła",
            .tr: "Parolalar", .ar: "كلمات السر", .th: "รหัสผ่าน",
            .vi: "Mật khẩu", .id: "Kata Sandi", .sv: "Lösenord",
            .da: "Adgangskoder", .nb: "Passord", .fi: "Salasanat",
            .cs: "Hesla", .uk: "Паролі"
        ],
        "com.apple.freeform": [
            .en: "Freeform", .zhHans: "无边记", .zhHant: "無邊記",
            .ja: "フリーボード", .ko: "Freeform", .fr: "Freeform",
            .de: "Freeform", .es: "Freeform", .it: "Freeform",
            .ru: "Freeform", .ar: "Freeform"
        ]
    ]

    /// 核心入口：根据 bundleId、目标语言与回退名动态解析显示名称
    public func resolve(bundleId: String, fallback: String, language: AppLanguage) -> String {
        guard !bundleId.isEmpty else { return fallback }

        let cacheKey = "\(bundleId)_\(language.rawValue)"
        lock.lock()
        if let cached = cache[cacheKey] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // 1. 系统核心组件映射表优先匹配
        if let dict = systemAppLocalizations[bundleId], let localized = dict[language] {
            lock.lock()
            cache[cacheKey] = localized
            lock.unlock()
            return localized
        }

        // 2. 第三方应用：从目标 App Bundle 动态读取 InfoPlist.strings
        if let resolved = resolveFromBundle(bundleId: bundleId, language: language) {
            lock.lock()
            cache[cacheKey] = resolved
            lock.unlock()
            return resolved
        }

        // 3. 兜底返回 scanner 获取的系统原始名称
        lock.lock()
        cache[cacheKey] = fallback
        lock.unlock()
        return fallback
    }

    private func resolveFromBundle(bundleId: String, language: AppLanguage) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }

        let candidates = candidateLocales(for: language)
        for cand in candidates {
            let plistUrl = url.appendingPathComponent("Contents/Resources/\(cand).lproj/InfoPlist.strings")
            if let data = try? Data(contentsOf: plistUrl),
               let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                if let dispName = plist["CFBundleDisplayName"] as? String, !dispName.isEmpty {
                    return dispName
                }
                if let name = plist["CFBundleName"] as? String, !name.isEmpty {
                    return name
                }
            }
        }
        return nil
    }

    private func candidateLocales(for language: AppLanguage) -> [String] {
        switch language {
        case .zhHans: return ["zh-Hans", "zh_CN", "zh"]
        case .zhHant: return ["zh-Hant", "zh_TW", "zh_HK"]
        case .en: return ["en", "en_US", "en_GB", "Base"]
        case .ja: return ["ja", "ja_JP"]
        case .ko: return ["ko", "ko_KR"]
        case .fr: return ["fr", "fr_FR", "fr_CA"]
        case .de: return ["de", "de_DE"]
        case .es: return ["es", "es_ES", "es_419"]
        case .pt: return ["pt", "pt_BR", "pt_PT"]
        case .it: return ["it", "it_IT"]
        case .ru: return ["ru", "ru_RU"]
        case .nl: return ["nl", "nl_NL"]
        case .pl: return ["pl", "pl_PL"]
        case .tr: return ["tr", "tr_TR"]
        case .ar: return ["ar"]
        case .th: return ["th", "th_TH"]
        case .vi: return ["vi", "vi_VN"]
        case .id: return ["id", "id_ID"]
        case .sv: return ["sv", "sv_SE"]
        case .da: return ["da", "da_DK"]
        case .nb: return ["nb", "no"]
        case .fi: return ["fi", "fi_FI"]
        case .cs: return ["cs", "cs_CZ"]
        case .uk: return ["uk", "uk_UA"]
        }
    }
}
