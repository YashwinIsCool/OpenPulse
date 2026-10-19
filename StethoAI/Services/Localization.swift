import Foundation
import Combine

/// Languages StethoAI supports in-app. Kept small and deliberate — the screening
/// path is translated first, since that's what a person being screened actually reads.
enum AppLanguage: String, CaseIterable, Identifiable {
    case en, hi, ta
    var id: String { rawValue }

    /// Shown in the picker, in the language's own script.
    var nativeName: String {
        switch self {
        case .en: return "English"
        case .hi: return "हिन्दी"
        case .ta: return "தமிழ்"
        }
    }

    var englishName: String {
        switch self {
        case .en: return "English"
        case .hi: return "Hindi"
        case .ta: return "Tamil"
        }
    }
}

/// Lightweight in-app localizer. Views observe the shared instance, so switching
/// language updates the UI instantly (no app restart). English source strings are
/// the keys; `t()` returns the translation or falls back to English.
///
/// NOTE: the Hindi and Tamil strings below are a working first draft and MUST be
/// reviewed by a native speaker / the clinical partner before any real screening —
/// health wording needs to be both accurate and reassuring in the local language.
final class Localizer: ObservableObject {
    static let shared = Localizer()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.storeKey) }
    }

    private static let storeKey = "app_language"

    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storeKey),
           let lang = AppLanguage(rawValue: saved) {
            language = lang
        } else {
            let pref = Locale.preferredLanguages.first ?? "en"
            if pref.hasPrefix("hi") { language = .hi }
            else if pref.hasPrefix("ta") { language = .ta }
            else { language = .en }
        }
    }

    func t(_ key: String) -> String {
        guard language != .en else { return key }
        return Self.table[language]?[key] ?? key
    }

    // MARK: - Translation table

    private static let table: [AppLanguage: [String: String]] = {
        var hi: [String: String] = [:]
        var ta: [String: String] = [:]
        for e in entries {
            hi[e.0] = e.1
            ta[e.0] = e.2
        }
        return [.hi: hi, .ta: ta]
    }()

    // (english, hindi, tamil)
    private static let entries: [(String, String, String)] = [
        // Language picker
        ("Language", "भाषा", "மொழி"),
        ("Choose your language", "अपनी भाषा चुनें", "உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்"),
        ("Done", "पूर्ण", "முடிந்தது"),

        // Heart rate instructions
        ("Heart rate check", "हृदय गति जाँच", "இதயத் துடிப்பு சரிபார்ப்பு"),
        ("Cover the rear camera and the flash with your fingertip, so no light leaks out.",
         "अपनी उँगली से पीछे के कैमरा और फ्लैश को ढकें, ताकि रोशनी बाहर न निकले।",
         "வெளிச்சம் வெளியேறாதபடி உங்கள் விரல் நுனியால் பின் கேமராவையும் ஃப்ளாஷையும் மூடுங்கள்."),
        ("Use your middle finger — it reaches the camera most comfortably.",
         "अपनी बीच वाली उँगली का उपयोग करें — यह कैमरे तक आसानी से पहुँचती है।",
         "உங்கள் நடு விரலைப் பயன்படுத்துங்கள் — அது கேமராவை எளிதாக அடையும்."),
        ("Rest your fingertip flat over the camera — gently, don't press hard.",
         "अपनी उँगली को कैमरे पर सपाट रखें — हल्के से, ज़ोर से न दबाएँ।",
         "உங்கள் விரல் நுனியை கேமரா மீது மெதுவாகப் படியுங்கள் — அழுத்தமாக அழுத்த வேண்டாம்."),
        ("Your fingertip should glow red once the flash turns on.",
         "फ्लैश चालू होने पर आपकी उँगली लाल चमकनी चाहिए।",
         "ஃப்ளாஷ் இயங்கியதும் உங்கள் விரல் நுனி சிவப்பாக ஒளிர வேண்டும்."),
        ("Hold still and wait — the timer starts once it finds a good signal.",
         "स्थिर रहें और प्रतीक्षा करें — अच्छा संकेत मिलते ही टाइमर शुरू होगा।",
         "அசையாமல் இருந்து காத்திருங்கள் — நல்ல சமிக்ஞை கிடைத்ததும் நேரம் தொடங்கும்."),
        ("Start", "शुरू करें", "தொடங்கு"),

        // Recording status
        ("Searching for pulse…", "नाड़ी खोजी जा रही है…", "நாடித் துடிப்பைத் தேடுகிறது…"),
        ("Almost — adjust your finger", "लगभग — अपनी उँगली ठीक करें", "கிட்டத்தட்ட — உங்கள் விரலைச் சரிசெய்யுங்கள்"),
        ("Good signal! Hold still", "अच्छा संकेत! स्थिर रहें", "நல்ல சமிக்ஞை! அசையாமல் இருங்கள்"),
        ("seconds remaining", "सेकंड शेष", "விநாடிகள் மீதம்"),
        ("Reading your pulse — hold still", "आपकी नाड़ी पढ़ी जा रही है — स्थिर रहें", "உங்கள் துடிப்பைப் படிக்கிறது — அசையாமல் இருங்கள்"),
        ("Paused — put your finger back on the lens", "रुका हुआ — अपनी उँगली फिर से लेंस पर रखें", "இடைநிறுத்தப்பட்டது — உங்கள் விரலை மீண்டும் லென்ஸ் மீது வையுங்கள்"),
        ("Cover the camera and the flash fully with your fingertip.",
         "अपनी उँगली से कैमरा और फ्लैश को पूरी तरह ढकें।",
         "உங்கள் விரல் நுனியால் கேமராவையும் ஃப்ளாஷையும் முழுமையாக மூடுங்கள்."),
        ("Rest your finger flat and gently — don't press hard.",
         "अपनी उँगली को सपाट और हल्के से रखें — ज़ोर से न दबाएँ।",
         "உங்கள் விரலை தட்டையாகவும் மெதுவாகவும் வையுங்கள் — அழுத்தமாக அழுத்த வேண்டாம்."),
        ("Keep holding — the timer is about to start.",
         "पकड़े रहें — टाइमर शुरू होने वाला है।",
         "தொடர்ந்து பிடித்திருங்கள் — நேரம் தொடங்கவிருக்கிறது."),

        // Result
        ("Save & Continue", "सहेजें और आगे बढ़ें", "சேமித்துத் தொடரவும்"),
        ("See where to get care", "देखें कहाँ से देखभाल मिलेगी", "எங்கு பராமரிப்பு பெறலாம் என்று பார்க்கவும்"),
        ("For educational and informational use only. Not medical advice. Consult a healthcare provider.",
         "केवल शैक्षिक और सूचनात्मक उपयोग के लिए। यह चिकित्सा सलाह नहीं है। किसी स्वास्थ्य विशेषज्ञ से परामर्श करें।",
         "கல்வி மற்றும் தகவல் நோக்கத்திற்காக மட்டுமே. இது மருத்துவ ஆலோசனை அல்ல. ஒரு சுகாதார நிபுணரை அணுகவும்."),
        ("This resting heart rate is in a typical range. Keep checking in over time.",
         "यह विश्राम हृदय गति सामान्य सीमा में है। समय-समय पर जाँचते रहें।",
         "இந்த ஓய்வு இதயத் துடிப்பு சாதாரண வரம்பில் உள்ளது. அவ்வப்போது சரிபார்த்துக் கொண்டிருங்கள்."),
        ("This is a little higher than a typical resting rate — often from activity, caffeine, or stress. If it stays high at rest, it's worth showing to a health worker.",
         "यह सामान्य विश्राम गति से थोड़ी अधिक है — अक्सर गतिविधि, कैफीन या तनाव के कारण। यदि यह आराम में भी अधिक रहे, तो किसी स्वास्थ्यकर्मी को दिखाएँ।",
         "இது சாதாரண ஓய்வு துடிப்பை விட சற்று அதிகம் — பெரும்பாலும் உடல் உழைப்பு, காஃபின் அல்லது மன அழுத்தத்தால். ஓய்விலும் அதிகமாக இருந்தால், ஒரு சுகாதாரப் பணியாளரிடம் காட்டுங்கள்."),
        ("This resting reading is high. It can be harmless, but it's worth having a health worker or doctor take a look.",
         "यह विश्राम गति अधिक है। यह हानिरहित हो सकती है, पर किसी स्वास्थ्यकर्मी या डॉक्टर को दिखाना बेहतर है।",
         "இந்த ஓய்வு துடிப்பு அதிகம். இது பாதிப்பில்லாததாக இருக்கலாம், ஆனால் ஒரு சுகாதாரப் பணியாளர் அல்லது மருத்துவரிடம் காட்டுவது நல்லது."),
        ("This resting reading is low. That's normal for some fit people, but if you feel dizzy or unwell, it's worth having someone check.",
         "यह विश्राम गति कम है। कुछ स्वस्थ लोगों के लिए यह सामान्य है, पर यदि चक्कर या तकलीफ हो तो किसी से जाँच कराएँ।",
         "இந்த ஓய்வு துடிப்பு குறைவு. சில ஆரோக்கியமானவர்களுக்கு இது சாதாரணம், ஆனால் தலைச்சுற்றல் அல்லது உடல்நலக்குறைவு இருந்தால் சரிபார்த்துக் கொள்ளுங்கள்."),

        // Care pathway
        ("Where to get care", "देखभाल कहाँ से पाएँ", "எங்கு பராமரிப்பு பெறலாம்"),
        ("Getting your heart checked", "अपने हृदय की जाँच कराना", "உங்கள் இதயத்தை பரிசோதிக்க"),
        ("Let's find you some care", "आइए आपके लिए देखभाल ढूँढें", "உங்களுக்குப் பராமரிப்பைத் தேடுவோம்"),
        ("This is only a reading, not a diagnosis — try not to worry. The best next step is to have a health worker or doctor take a look. Here's where you can start, close to you and low-cost or free.",
         "यह केवल एक माप है, कोई निदान नहीं — चिंता न करें। सबसे अच्छा अगला कदम है किसी स्वास्थ्यकर्मी या डॉक्टर को दिखाना। यहाँ से शुरुआत करें — आपके पास, कम खर्च या मुफ़्त।",
         "இது ஒரு அளவீடு மட்டுமே, நோயறிதல் அல்ல — கவலைப்பட வேண்டாம். அடுத்த சிறந்த படி ஒரு சுகாதாரப் பணியாளர் அல்லது மருத்துவரிடம் காட்டுவது. உங்களுக்கு அருகில், குறைந்த செலவில் அல்லது இலவசமாக இங்கே தொடங்கலாம்."),
        ("If you ever want a professional to check your heart, here are low-cost and free places to start — no matter where you are.",
         "यदि आप कभी किसी विशेषज्ञ से अपने हृदय की जाँच कराना चाहें, तो यहाँ कम खर्च और मुफ़्त स्थान दिए गए हैं — आप कहीं भी हों।",
         "உங்கள் இதயத்தை ஒரு நிபுணர் பரிசோதிக்க விரும்பினால், இங்கே குறைந்த செலவு மற்றும் இலவச இடங்கள் உள்ளன — நீங்கள் எங்கிருந்தாலும்."),
        ("Nearest government health centre", "नज़दीकी सरकारी स्वास्थ्य केंद्र", "அருகிலுள்ள அரசு சுகாதார மையம்"),
        ("Primary Health Centres (PHCs) and Community Health Centres offer free or low-cost check-ups. A health worker can measure your blood pressure and refer you further if needed.",
         "प्राथमिक स्वास्थ्य केंद्र (PHC) और सामुदायिक स्वास्थ्य केंद्र मुफ़्त या कम खर्च में जाँच करते हैं। स्वास्थ्यकर्मी आपका रक्तचाप माप सकते हैं और ज़रूरत पड़ने पर आगे भेज सकते हैं।",
         "முதன்மை சுகாதார மையங்கள் (PHC) மற்றும் சமூக சுகாதார மையங்கள் இலவச அல்லது குறைந்த செலவில் பரிசோதனை வழங்குகின்றன. ஒரு பணியாளர் உங்கள் இரத்த அழுத்தத்தை அளந்து தேவைப்பட்டால் மேலும் பரிந்துரைக்கலாம்."),
        ("Ayushman Bharat (PM-JAY)", "आयुष्मान भारत (पीएम-जेएवाई)", "ஆயுஷ்மான் பாரத் (PM-JAY)"),
        ("A government scheme that covers free hospital care for eligible families. Many people who qualify don't know they're eligible — ask a health worker to help you check.",
         "एक सरकारी योजना जो पात्र परिवारों के लिए मुफ़्त अस्पताल देखभाल देती है। कई पात्र लोग नहीं जानते कि वे पात्र हैं — किसी स्वास्थ्यकर्मी से जाँच में मदद लें।",
         "தகுதியான குடும்பங்களுக்கு இலவச மருத்துவமனை பராமரிப்பை வழங்கும் அரசு திட்டம். தகுதியானவர்கள் பலருக்கு தாங்கள் தகுதியுடையவர் என்று தெரியாது — சரிபார்க்க ஒரு பணியாளரிடம் உதவி கேளுங்கள்."),
        ("Your community health worker (ASHA)", "आपकी आशा स्वास्थ्य कार्यकर्ता", "உங்கள் ஆஷா சுகாதாரப் பணியாளர்"),
        ("ASHA workers can guide you to the right care, help with government schemes, and follow up with you locally.",
         "आशा कार्यकर्ता आपको सही देखभाल तक पहुँचा सकती हैं, सरकारी योजनाओं में मदद कर सकती हैं, और स्थानीय रूप से आपका ध्यान रख सकती हैं।",
         "ஆஷா பணியாளர்கள் சரியான பராமரிப்புக்கு வழிகாட்டலாம், அரசு திட்டங்களில் உதவலாம், உள்ளூரில் தொடர்ந்து கவனிக்கலாம்."),
        ("Partner clinic / health camp", "साझेदार क्लिनिक / स्वास्थ्य शिविर", "கூட்டாளர் மருத்துவமனை / சுகாதார முகாம்"),
        ("If you were screened at a StethoAI health camp, the clinician there can review your reading and tell you the next step. Show them your saved heart record.",
         "यदि आपकी जाँच किसी StethoAI स्वास्थ्य शिविर में हुई थी, तो वहाँ के चिकित्सक आपकी रीडिंग देखकर अगला कदम बता सकते हैं। उन्हें अपना सहेजा हुआ हृदय रिकॉर्ड दिखाएँ।",
         "நீங்கள் ஒரு StethoAI சுகாதார முகாமில் பரிசோதிக்கப்பட்டிருந்தால், அங்குள்ள மருத்துவர் உங்கள் அளவீட்டைப் பார்த்து அடுத்த படியைச் சொல்லலாம். உங்கள் சேமித்த இதயப் பதிவைக் காட்டுங்கள்."),
        ("Emergency", "आपातकाल", "அவசரநிலை"),
        ("If you have chest pain, trouble breathing, fainting, or feel very unwell right now, seek help immediately.",
         "यदि अभी आपको सीने में दर्द, साँस लेने में तकलीफ, बेहोशी या बहुत अस्वस्थ महसूस हो, तो तुरंत मदद लें।",
         "இப்போது மார்பு வலி, மூச்சுத் திணறல், மயக்கம் அல்லது மிகவும் உடல்நலக்குறைவு இருந்தால், உடனடியாக உதவி பெறுங்கள்."),
        ("Learn about eligibility", "पात्रता के बारे में जानें", "தகுதி பற்றி அறியவும்"),
        ("Call 108 (ambulance)", "108 पर कॉल करें (एम्बुलेंस)", "108 ஐ அழைக்கவும் (ஆம்புலன்ஸ்)"),
        ("StethoAI is for awareness and education — not a diagnosis. These are starting points for finding care, not medical advice.",
         "StethoAI जागरूकता और शिक्षा के लिए है — कोई निदान नहीं। ये देखभाल खोजने के शुरुआती बिंदु हैं, चिकित्सा सलाह नहीं।",
         "StethoAI விழிப்புணர்வு மற்றும் கல்விக்காக — நோயறிதல் அல்ல. இவை பராமரிப்பைக் கண்டறியும் தொடக்கப் புள்ளிகள், மருத்துவ ஆலோசனை அல்ல."),

        // Home
        ("Hello", "नमस्ते", "வணக்கம்"),
        ("Hi", "नमस्ते", "வணக்கம்"),
        ("Check your heart", "अपना दिल जाँचें", "உங்கள் இதயத்தைச் சரிபார்க்கவும்"),
        ("You checked today", "आज आपने जाँच कर ली है", "இன்று நீங்கள் சரிபார்த்துவிட்டீர்கள்"),
        ("30 seconds. Rest a fingertip on the back camera.",
         "30 सेकंड। अपनी उंगली का सिरा पीछे वाले कैमरे पर रखें।",
         "30 வினாடிகள். பின் கேமராவில் உங்கள் விரல் நுனியை வைக்கவும்."),
        ("Start check", "जाँच शुरू करें", "சரிபார்ப்பைத் தொடங்கவும்"),
        ("Check again", "फिर से जाँचें", "மீண்டும் சரிபார்க்கவும்"),
        ("Last check", "पिछली जाँच", "கடைசி சரிபார்ப்பு"),
        ("today", "आज", "இன்று"),
        ("yesterday", "कल", "நேற்று"),
        ("Guided check", "निर्देशित जाँच", "வழிகாட்டப்பட்ட சரிபார்ப்பு"),
        ("Check, breathe, and check again", "जाँचें, साँस लें, और फिर से जाँचें", "சரிபார்க்கவும், மூச்சு விடவும், மீண்டும் சரிபார்க்கவும்"),
        ("Breathing exercise", "साँस का व्यायाम", "மூச்சுப் பயிற்சி"),
        ("Record heart sound", "दिल की आवाज़ रिकॉर्ड करें", "இதய ஒலியைப் பதிவு செய்யவும்"),
        ("Suggested today", "आज के लिए सुझाव", "இன்று பரிந்துரைக்கப்படுகிறது"),
        ("Your insights", "आपकी जानकारी", "உங்கள் நுண்ணறிவுகள்"),
        ("Low", "कम", "குறைவு"),
        ("Normal", "सामान्य", "இயல்பு"),
        ("A little high", "थोड़ा ज़्यादा", "சற்று அதிகம்"),
        ("High", "ज़्यादा", "அதிகம்"),

        // Heart rate result
        ("Your heart rate", "आपकी हृदय गति", "உங்கள் இதயத் துடிப்பு"),
        ("Lower than usual at rest", "आराम के समय सामान्य से कम", "ஓய்வில் வழக்கத்தை விடக் குறைவு"),
        ("Normal for a resting heart", "आराम के समय सामान्य", "ஓய்வில் இயல்பானது"),
        ("A little higher than usual", "सामान्य से थोड़ा ज़्यादा", "வழக்கத்தை விடச் சற்று அதிகம்"),
        ("Higher than usual at rest", "आराम के समय सामान्य से ज़्यादा", "ஓய்வில் வழக்கத்தை விட அதிகம்"),
        ("Heart rate variability", "हृदय गति परिवर्तनशीलता", "இதயத் துடிப்பு மாறுபாடு"),
        ("Where to go", "कहाँ जाएँ", "எங்கு செல்லலாம்"),
    ]
}
