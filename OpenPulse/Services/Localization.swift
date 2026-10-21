import Foundation
import Combine

/// Languages OpenPulse supports in-app. Kept small and deliberate — the screening
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
        ("A local clinic or health center", "कोई स्थानीय क्लिनिक या स्वास्थ्य केंद्र", "அருகிலுள்ள மருத்துவமனை அல்லது சுகாதார மையம்"),
        ("Many communities have public or community health centers with free or low-cost check-ups. A nurse or health worker can check your blood pressure and refer you if needed.",
         "कई जगहों पर सरकारी या सामुदायिक स्वास्थ्य केंद्र होते हैं जहाँ मुफ़्त या कम खर्च में जाँच होती है। कोई नर्स या स्वास्थ्य कार्यकर्ता आपका रक्तचाप जाँच सकता है और ज़रूरत हो तो आगे भेज सकता है।",
         "பல இடங்களில் இலவசமாக அல்லது குறைந்த செலவில் பரிசோதனை செய்யும் அரசு அல்லது சமூக சுகாதார மையங்கள் உள்ளன. ஒரு செவிலியர் அல்லது சுகாதாரப் பணியாளர் உங்கள் இரத்த அழுத்தத்தைச் சரிபார்த்து, தேவைப்பட்டால் மேல் சிகிச்சைக்கு அனுப்பலாம்."),
        ("A doctor or pharmacist", "डॉक्टर या फार्मासिस्ट", "மருத்துவர் அல்லது மருந்தாளர்"),
        ("If you have a doctor, show them your readings. Many pharmacists can check your blood pressure for free and tell you where to go next.",
         "अगर आपके कोई डॉक्टर हैं, तो उन्हें अपनी रीडिंग दिखाएँ। कई फार्मासिस्ट मुफ़्त में रक्तचाप जाँच सकते हैं और बता सकते हैं कि आगे कहाँ जाएँ।",
         "உங்களுக்கு மருத்துவர் இருந்தால், உங்கள் அளவீடுகளைக் காட்டுங்கள். பல மருந்தாளர்கள் இலவசமாக இரத்த அழுத்தத்தைச் சரிபார்த்து, அடுத்து எங்கு செல்லலாம் என்று சொல்வார்கள்."),
        ("A nurse or health advice line", "नर्स या स्वास्थ्य सलाह हेल्पलाइन", "செவிலியர் அல்லது சுகாதார ஆலோசனை உதவி எண்"),
        ("Many countries have a free phone line where a nurse can tell you how urgent things are and where to go. Search for your country's health advice line.",
         "कई देशों में एक मुफ़्त फ़ोन लाइन होती है जहाँ नर्स बता सकती है कि स्थिति कितनी ज़रूरी है और कहाँ जाना है। अपने देश की स्वास्थ्य सलाह हेल्पलाइन खोजें।",
         "பல நாடுகளில் இலவச தொலைபேசி எண் உள்ளது; அங்கு ஒரு செவிலியர் நிலைமை எவ்வளவு அவசரம், எங்கு செல்ல வேண்டும் என்று சொல்வார். உங்கள் நாட்டின் சுகாதார ஆலோசனை எண்ணைத் தேடுங்கள்."),
        ("Bring your heart record", "अपना हृदय रिकॉर्ड साथ ले जाएँ", "உங்கள் இதயப் பதிவைக் கொண்டு செல்லுங்கள்"),
        ("In the History tab, tap Share with a doctor to make a one-page record of your readings, so a clinician sees the pattern, not just one number.",
         "हिस्ट्री टैब में \"डॉक्टर के साथ साझा करें\" दबाकर अपनी रीडिंग का एक पेज का रिकॉर्ड बनाएँ, ताकि डॉक्टर सिर्फ़ एक संख्या नहीं, पूरा पैटर्न देख सकें।",
         "வரலாறு தாவலில் \"மருத்துவருடன் பகிரவும்\" என்பதைத் தட்டி, உங்கள் அளவீடுகளின் ஒரு பக்கப் பதிவை உருவாக்குங்கள்; அப்போது மருத்துவர் ஒரு எண்ணை மட்டுமல்ல, முழுப் போக்கையும் பார்ப்பார்."),
        ("Emergency", "आपातकाल", "அவசரநிலை"),
        ("If you have chest pain, trouble breathing, fainting, or feel very unwell right now, seek help immediately.",
         "यदि अभी आपको सीने में दर्द, साँस लेने में तकलीफ, बेहोशी या बहुत अस्वस्थ महसूस हो, तो तुरंत मदद लें।",
         "இப்போது மார்பு வலி, மூச்சுத் திணறல், மயக்கம் அல்லது மிகவும் உடல்நலக்குறைவு இருந்தால், உடனடியாக உதவி பெறுங்கள்."),
        ("Call emergency services", "आपातकालीन सेवा को कॉल करें", "அவசர சேவையை அழைக்கவும்"),
        ("OpenPulse is for awareness and education — not a diagnosis. These are starting points for finding care, not medical advice.",
         "OpenPulse जागरूकता और शिक्षा के लिए है — कोई निदान नहीं। ये देखभाल खोजने के शुरुआती बिंदु हैं, चिकित्सा सलाह नहीं।",
         "OpenPulse விழிப்புணர்வு மற்றும் கல்விக்காக — நோயறிதல் அல்ல. இவை பராமரிப்பைக் கண்டறியும் தொடக்கப் புள்ளிகள், மருத்துவ ஆலோசனை அல்ல."),

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
        // Tabs, History, Help
        ("Check", "जाँच", "சரிபார்ப்பு"),
        ("History", "इतिहास", "வரலாறு"),
        ("Help", "मदद", "உதவி"),
        ("Week", "सप्ताह", "வாரம்"),
        ("Month", "महीना", "மாதம்"),
        ("Year", "साल", "ஆண்டு"),
        ("Average", "औसत", "சராசரி"),
        ("day checked", "दिन जाँच की", "நாள் சரிபார்க்கப்பட்டது"),
        ("days checked", "दिन जाँच की", "நாட்கள் சரிபார்க்கப்பட்டன"),
        ("Readings", "रीडिंग", "அளவீடுகள்"),
        ("Show all", "सभी दिखाएँ", "அனைத்தையும் காட்டு"),
        ("Show fewer", "कम दिखाएँ", "குறைவாகக் காட்டு"),
        ("Heart sounds", "दिल की आवाज़ें", "இதய ஒலிகள்"),
        ("Recordings you make will appear here, ready to play or share.",
         "आपकी रिकॉर्डिंग यहाँ दिखेंगी, सुनने या साझा करने के लिए तैयार।",
         "நீங்கள் செய்யும் பதிவுகள் இங்கே தோன்றும், கேட்க அல்லது பகிரத் தயாராக."),
        ("No checks yet", "अभी तक कोई जाँच नहीं", "இன்னும் சரிபார்ப்பு இல்லை"),
        ("Your readings will show up here after your first heart check.",
         "पहली जाँच के बाद आपकी रीडिंग यहाँ दिखेंगी।",
         "உங்கள் முதல் சரிபார்ப்புக்குப் பிறகு அளவீடுகள் இங்கே தோன்றும்."),
        ("Share with a doctor", "डॉक्टर के साथ साझा करें", "மருத்துவருடன் பகிரவும்"),
        ("Free and low-cost places to start", "मुफ़्त और कम खर्च वाली जगहें", "இலவச மற்றும் குறைந்த செலவு இடங்கள்"),
        ("Heart health basics", "हृदय स्वास्थ्य की बुनियादी बातें", "இதய ஆரோக்கிய அடிப்படைகள்"),
        ("Settings", "सेटिंग्स", "அமைப்புகள்"),
        ("Account", "खाता", "கணக்கு"),
        ("Notifications", "सूचनाएँ", "அறிவிப்புகள்"),
        ("About", "परिचय", "பற்றி"),
        ("About OpenPulse", "OpenPulse के बारे में", "OpenPulse பற்றி"),
        ("Privacy and terms", "गोपनीयता और शर्तें", "தனியுரிமை மற்றும் விதிமுறைகள்"),
        ("Share OpenPulse", "OpenPulse साझा करें", "OpenPulse ஐப் பகிரவும்"),
        ("Send feedback", "सुझाव भेजें", "கருத்து அனுப்பவும்"),
        ("OpenPulse is a wellness and education tool. It is not a medical device and does not diagnose conditions.",
         "OpenPulse एक स्वास्थ्य जागरूकता और शिक्षा उपकरण है। यह कोई चिकित्सा उपकरण नहीं है और किसी बीमारी का निदान नहीं करता।",
         "OpenPulse ஒரு நலவாழ்வு மற்றும் கல்வி கருவி. இது மருத்துவச் சாதனம் அல்ல, எந்த நோயையும் கண்டறியாது."),

        // Quiz, account, personal heart model
        ("What should we call you?", "हम आपको क्या कहकर बुलाएँ?", "உங்களை எப்படி அழைக்கலாம்?"),
        ("How old are you?", "आपकी उम्र कितनी है?", "உங்கள் வயது என்ன?"),
        ("What's your sex?", "आपका लिंग क्या है?", "உங்கள் பாலினம் என்ன?"),
        ("How often do you exercise?", "आप कितनी बार व्यायाम करते हैं?", "நீங்கள் எவ்வளவு அடிக்கடி உடற்பயிற்சி செய்கிறீர்கள்?"),
        ("Want a daily reminder?", "क्या आप रोज़ याद दिलाना चाहेंगे?", "தினசரி நினைவூட்டல் வேண்டுமா?"),
        ("Just a first name or nickname. Everything you answer stays on this phone.", "सिर्फ़ पहला नाम या उपनाम। आपके सभी जवाब इसी फ़ोन में रहते हैं।", "முதல் பெயர் அல்லது புனைப்பெயர் போதும். நீங்கள் சொல்வது எல்லாம் இந்த ஃபோனிலேயே இருக்கும்."),
        ("Typical heart rates change with age, so this helps put your readings in context.", "उम्र के साथ सामान्य हृदय गति बदलती है, इसलिए इससे आपकी रीडिंग को समझने में मदद मिलती है।", "வயதுக்கு ஏற்ப இயல்பான இதயத் துடிப்பு மாறும், எனவே இது உங்கள் அளவீடுகளைப் புரிந்துகொள்ள உதவும்."),
        ("On average, resting heart rates differ a little between women and men.", "औसतन, महिलाओं और पुरुषों की आराम की हृदय गति में थोड़ा अंतर होता है।", "சராசரியாக, பெண்கள் மற்றும் ஆண்களின் ஓய்வு இதயத் துடிப்பு சற்று வேறுபடும்."),
        ("Active people often have a lower resting heart rate. This helps us understand yours.", "सक्रिय लोगों की आराम की हृदय गति अक्सर कम होती है। इससे हमें आपकी हृदय गति समझने में मदद मिलती है।", "சுறுசுறுப்பானவர்களுக்கு ஓய்வு இதயத் துடிப்பு பெரும்பாலும் குறைவாக இருக்கும். இது உங்களுடையதைப் புரிந்துகொள்ள உதவும்."),
        ("A gentle nudge each morning to check your heart. You can change this any time.", "हर सुबह दिल जाँचने की एक हल्की याद। आप इसे कभी भी बदल सकते हैं।", "ஒவ்வொரு காலையும் இதயத்தைச் சரிபார்க்க ஒரு மென்மையான நினைவூட்டல். இதை எப்போது வேண்டுமானாலும் மாற்றலாம்."),
        ("Continue", "आगे बढ़ें", "தொடரவும்"),
        ("Finish", "पूरा करें", "முடிக்கவும்"),
        ("Skip", "छोड़ें", "தவிர்"),
        ("First name", "पहला नाम", "முதல் பெயர்"),
        ("years", "साल", "வயது"),
        ("Female", "महिला", "பெண்"),
        ("Male", "पुरुष", "ஆண்"),
        ("Prefer not to say", "बताना नहीं चाहते", "சொல்ல விரும்பவில்லை"),
        ("Not set", "सेट नहीं", "அமைக்கப்படவில்லை"),
        ("Rarely or never", "कभी-कभार या कभी नहीं", "அரிதாக அல்லது ஒருபோதும் இல்லை"),
        ("1–2 days a week", "हफ़्ते में 1–2 दिन", "வாரத்தில் 1–2 நாட்கள்"),
        ("3–4 days a week", "हफ़्ते में 3–4 दिन", "வாரத்தில் 3–4 நாட்கள்"),
        ("Most days", "ज़्यादातर दिन", "பெரும்பாலான நாட்கள்"),
        ("Training, sports, or hard workouts", "ट्रेनिंग, खेल या कड़ा व्यायाम", "பயிற்சி, விளையாட்டு அல்லது கடுமையான உடற்பயிற்சி"),
        ("Regular walks, runs, or workouts", "नियमित सैर, दौड़ या व्यायाम", "வழக்கமான நடை, ஓட்டம் அல்லது உடற்பயிற்சி"),
        ("Yes, remind me", "हाँ, याद दिलाएँ", "ஆம், நினைவூட்டுங்கள்"),
        ("No thanks", "नहीं, धन्यवाद", "வேண்டாம், நன்றி"),
        ("Age", "उम्र", "வயது"),
        ("Sex", "लिंग", "பாலினம்"),
        ("Exercise", "व्यायाम", "உடற்பயிற்சி"),
        ("These answers give your readings and insights context. They stay on this phone.", "ये जवाब आपकी रीडिंग और जानकारी को संदर्भ देते हैं। ये इसी फ़ोन में रहते हैं।", "இந்தப் பதில்கள் உங்கள் அளவீடுகளுக்கும் நுண்ணறிவுகளுக்கும் சூழலைத் தருகின்றன. இவை இந்த ஃபோனிலேயே இருக்கும்."),
        ("A resting rate in the 40s is common for very active people.", "बहुत सक्रिय लोगों में आराम की हृदय गति 40 के आसपास होना आम है।", "மிகவும் சுறுசுறுப்பானவர்களுக்கு ஓய்வு இதயத் துடிப்பு 40களில் இருப்பது வழக்கம்."),
        ("Usual for you right now", "अभी आपके लिए सामान्य", "இப்போது உங்களுக்கு வழக்கமானது"),
        ("This reading is in line with your usual.", "यह रीडिंग आपकी सामान्य रीडिंग जैसी ही है।", "இந்த அளவீடு உங்கள் வழக்கமான அளவுக்கு ஏற்ப உள்ளது."),
        ("This is higher than usual for you. Caffeine, stress, activity, or not resting first can all raise it.", "यह आपके लिए सामान्य से ज़्यादा है। कैफ़ीन, तनाव, गतिविधि या पहले आराम न करना इसे बढ़ा सकते हैं।", "இது உங்களுக்கு வழக்கத்தை விட அதிகம். காஃபின், மன அழுத்தம், செயல்பாடு அல்லது முதலில் ஓய்வெடுக்காதது இதை உயர்த்தலாம்."),
        ("This is lower than usual for you.", "यह आपके लिए सामान्य से कम है।", "இது உங்களுக்கு வழக்கத்தை விடக் குறைவு."),
        ("Learned on this phone from %d of your readings.", "इस फ़ोन पर आपकी %d रीडिंग से सीखा गया।", "இந்த ஃபோனில் உங்கள் %d அளவீடுகளிலிருந்து கற்றது."),
        ("A starting estimate from your profile. It becomes personal after 7 readings.", "आपकी प्रोफ़ाइल से शुरुआती अनुमान। 7 रीडिंग के बाद यह आपके हिसाब से बन जाता है।", "உங்கள் விவரங்களிலிருந்து ஒரு தொடக்க மதிப்பீடு. 7 அளவீடுகளுக்குப் பிறகு இது உங்களுக்கென மாறும்."),
        ("Wellness patterns from your own data, not medical advice.", "आपके अपने डेटा से स्वास्थ्य पैटर्न, चिकित्सा सलाह नहीं।", "உங்கள் சொந்த தரவிலிருந்து நலவாழ்வு போக்குகள், மருத்துவ ஆலோசனை அல்ல."),
        ("Your heart model", "आपका हृदय मॉडल", "உங்கள் இதய மாதிரி"),
        ("Learns what's usual for you, on this phone", "इसी फ़ोन पर सीखता है कि आपके लिए क्या सामान्य है", "உங்களுக்கு எது வழக்கம் என்பதை இந்த ஃபோனிலேயே கற்றுக்கொள்கிறது"),
        ("Learned from", "इससे सीखा", "கற்றது"),
        ("reading", "रीडिंग", "அளவீடு"),
        ("readings", "रीडिंग", "அளவீடுகள்"),
        ("Usually accurate to within", "आम तौर पर इतने के भीतर सही", "பொதுவாக இந்த அளவுக்குள் சரியானது"),
        ("For now this is a starting estimate from your profile. It becomes personal after 7 readings.", "अभी यह आपकी प्रोफ़ाइल से शुरुआती अनुमान है। 7 रीडिंग के बाद यह आपके हिसाब से बन जाता है।", "இப்போதைக்கு இது உங்கள் விவரங்களிலிருந்து ஒரு தொடக்க மதிப்பீடு. 7 அளவீடுகளுக்குப் பிறகு இது உங்களுக்கென மாறும்."),
        ("What moves your heart rate", "आपकी हृदय गति को क्या बदलता है", "உங்கள் இதயத் துடிப்பை எது மாற்றுகிறது"),
        ("After %d more readings with check-ins, you'll see what raises and lowers your heart rate.", "चेक-इन के साथ %d और रीडिंग के बाद, आप देखेंगे कि आपकी हृदय गति को क्या बढ़ाता और घटाता है।", "சரிபார்ப்புகளுடன் இன்னும் %d அளவீடுகளுக்குப் பிறகு, உங்கள் இதயத் துடிப்பை எது உயர்த்துகிறது, எது குறைக்கிறது என்று பார்ப்பீர்கள்."),
        ("Nothing stands out yet. Keep checking in on different kinds of days.", "अभी कुछ खास नहीं दिखा। अलग-अलग तरह के दिनों में जाँच करते रहें।", "இன்னும் எதுவும் தனித்துத் தெரியவில்லை. பல்வேறு நாட்களில் தொடர்ந்து சரிபார்க்கவும்."),
        ("Each hour less sleep", "हर एक घंटा कम नींद", "ஒவ்வொரு மணி நேரம் குறைவான தூக்கம்"),
        ("Each caffeinated drink", "हर कैफ़ीन वाला पेय", "ஒவ்வொரு காஃபின் பானமும்"),
        ("Days you exercise", "जिन दिनों आप व्यायाम करते हैं", "நீங்கள் உடற்பயிற்சி செய்யும் நாட்கள்"),
        ("Each step up in stress", "तनाव में हर एक बढ़त", "மன அழுத்தத்தில் ஒவ்வொரு படி உயர்வும்"),
        ("Each step up in mood", "मूड में हर एक बढ़त", "மனநிலையில் ஒவ்வொரு படி உயர்வும்"),
        ("Afternoon and evening checks", "दोपहर और शाम की जाँच", "மதியம் மற்றும் மாலை சரிபார்ப்புகள்"),
        ("Estimated by a small machine-learning model trained only on your readings and check-ins. Nothing leaves your phone.", "एक छोटे मशीन-लर्निंग मॉडल ने केवल आपकी रीडिंग और चेक-इन से इसका अनुमान लगाया है। कुछ भी आपके फ़ोन से बाहर नहीं जाता।", "உங்கள் அளவீடுகள் மற்றும் சரிபார்ப்புகளில் மட்டுமே பயிற்சி பெற்ற ஒரு சிறிய இயந்திரக் கற்றல் மாதிரி இதை மதிப்பிட்டது. எதுவும் உங்கள் ஃபோனை விட்டு வெளியேறாது."),
        ("Patterns", "पैटर्न", "போக்குகள்"),
        ("Days analyzed", "विश्लेषित दिन", "பகுப்பாய்வு செய்யப்பட்ட நாட்கள்"),
        ("Check your heart and do a check-in on %d more days to see your patterns.", "अपने पैटर्न देखने के लिए %d और दिन दिल जाँचें और चेक-इन करें।", "உங்கள் போக்குகளைப் பார்க்க இன்னும் %d நாட்கள் இதயத்தைச் சரிபார்த்து சரிபார்ப்பைச் செய்யுங்கள்."),

        // Heart rate reading screen
        ("Reading your pulse", "आपकी नब्ज़ पढ़ी जा रही है", "உங்கள் நாடித்துடிப்பு படிக்கப்படுகிறது"),
        ("Put your finger back on the camera", "उंगली वापस कैमरे पर रखें", "விரலை மீண்டும் கேமராவில் வைக்கவும்"),
        ("The timer will continue when it's covered again.", "कैमरा फिर से ढकने पर टाइमर चालू हो जाएगा।", "கேமரா மீண்டும் மூடப்பட்டதும் டைமர் தொடரும்."),
        ("Cover the camera and the flash", "कैमरा और फ़्लैश को ढकें", "கேமராவையும் ஃபிளாஷையும் மூடவும்"),
        ("Rest one fingertip over the back camera lens and the light beside it. The circle should turn bright red.", "एक उंगली का सिरा पीछे के कैमरा लेंस और उसके पास की लाइट पर रखें। गोला चमकीला लाल हो जाना चाहिए।", "ஒரு விரல் நுனியைப் பின் கேமரா லென்ஸ் மற்றும் அதன் அருகிலுள்ள விளக்கின் மீது வைக்கவும். வட்டம் பிரகாசமான சிவப்பாக மாற வேண்டும்."),
        ("Press a little lighter", "थोड़ा हल्का दबाएँ", "சற்று மெதுவாக அழுத்தவும்"),
        ("Rest your finger gently. Pressing hard hides your pulse.", "उंगली हल्के से रखें। ज़ोर से दबाने पर नब्ज़ छिप जाती है।", "விரலை மெதுவாக வைக்கவும். அழுத்தமாக அழுத்தினால் நாடித்துடிப்பு மறைந்துவிடும்."),
        ("Almost there, keep holding", "बस थोड़ा और, ऐसे ही रखें", "கிட்டத்தட்ட முடிந்தது, தொடர்ந்து பிடிக்கவும்"),
        ("A few more seconds for a clean reading.", "सटीक रीडिंग के लिए कुछ सेकंड और।", "தெளிவான அளவீட்டுக்கு இன்னும் சில வினாடிகள்."),
        ("Good, hold still", "अच्छा, स्थिर रहें", "நல்லது, அசையாமல் இருங்கள்"),
        ("Starting in a moment.", "कुछ ही पल में शुरू होगा।", "சில நொடிகளில் தொடங்கும்."),
        ("Keep still and breathe normally.", "स्थिर रहें और सामान्य रूप से साँस लें।", "அசையாமல் இருந்து இயல்பாக மூச்சு விடுங்கள்."),
        ("Hold still", "स्थिर रहें", "அசையாமல் இருங்கள்"),
        ("Finding a clearer pulse. Keep your finger relaxed.", "साफ़ नब्ज़ ढूँढी जा रही है। उंगली ढीली रखें।", "தெளிவான நாடித்துடிப்பைத் தேடுகிறது. விரலைத் தளர்வாக வைக்கவும்."),
        ("Cancel", "रद्द करें", "ரத்து செய்"),

        // Restyled screens (Oct 20)
        ("A free heart check with just your phone", "सिर्फ़ अपने फ़ोन से मुफ़्त हृदय जाँच", "உங்கள் ஃபோன் மட்டும் போதும் — இலவச இதயச் சரிபார்ப்பு"),
        ("Measure your heart rate with your phone's camera.", "अपने फ़ोन के कैमरे से हृदय गति मापें।", "உங்கள் ஃபோன் கேமராவால் இதயத் துடிப்பை அளவிடுங்கள்."),
        ("Keep a heart record you can show a doctor.", "एक हृदय रिकॉर्ड रखें जो आप डॉक्टर को दिखा सकें।", "மருத்துவரிடம் காட்டக்கூடிய இதயப் பதிவை வைத்திருங்கள்."),
        ("Find care when a reading looks unusual.", "रीडिंग असामान्य लगे तो देखभाल ढूँढें।", "அளவீடு வழக்கத்துக்கு மாறாக இருந்தால் சிகிச்சையைக் கண்டறியுங்கள்."),
        ("Get started", "शुरू करें", "தொடங்குங்கள்"),
        ("Wellness and education only. Not a medical device.", "केवल स्वास्थ्य जागरूकता और शिक्षा के लिए। यह चिकित्सा उपकरण नहीं है।", "நலவாழ்வு மற்றும் கல்விக்காக மட்டும். இது மருத்துவச் சாதனம் அல்ல."),
        ("Allow access", "अनुमति दें", "அனுமதி அளியுங்கள்"),
        ("Everything is measured on this phone. No photos, video, or audio are uploaded.", "सब कुछ इसी फ़ोन पर मापा जाता है। कोई फ़ोटो, वीडियो या ऑडियो अपलोड नहीं होता।", "எல்லாமே இந்த ஃபோனிலேயே அளவிடப்படுகிறது. புகைப்படம், வீடியோ அல்லது ஆடியோ எதுவும் பதிவேற்றப்படாது."),
        ("Camera", "कैमरा", "கேமரா"),
        ("Measures your heart rate from tiny color changes in your fingertip.", "उंगली के सिरे के रंग में छोटे बदलावों से हृदय गति मापता है।", "விரல் நுனியின் நுண்ணிய நிற மாற்றங்களிலிருந்து இதயத் துடிப்பை அளவிடுகிறது."),
        ("Microphone", "माइक्रोफ़ोन", "மைக்ரோஃபோன்"),
        ("Records your heart sound when you hold the phone to your chest.", "फ़ोन को छाती से लगाने पर दिल की आवाज़ रिकॉर्ड करता है।", "ஃபோனை மார்பில் வைக்கும்போது இதய ஒலியைப் பதிவு செய்கிறது."),
        ("Gentle reminders for your daily check.", "रोज़ की जाँच के लिए हल्की याद।", "தினசரி சரிபார்ப்புக்கான மென்மையான நினைவூட்டல்கள்."),
        ("You can skip these and allow them later.", "आप इन्हें अभी छोड़कर बाद में अनुमति दे सकते हैं।", "இவற்றைத் தவிர்த்துப் பிறகு அனுமதிக்கலாம்."),
        ("Allow", "अनुमति दें", "அனுமதி"),
        ("Version", "संस्करण", "பதிப்பு"),
        ("What it does", "यह क्या करता है", "இது என்ன செய்கிறது"),
        ("A free heart check that uses your phone's camera to measure your heart rate, keeps a record you can show a doctor, and points you to care when a reading looks unusual.", "एक मुफ़्त हृदय जाँच जो फ़ोन के कैमरे से हृदय गति मापती है, डॉक्टर को दिखाने लायक रिकॉर्ड रखती है, और रीडिंग असामान्य लगने पर देखभाल की राह दिखाती है।", "ஃபோன் கேமராவால் இதயத் துடிப்பை அளவிட்டு, மருத்துவரிடம் காட்டக்கூடிய பதிவை வைத்து, அளவீடு அசாதாரணமாக இருந்தால் சிகிச்சைக்கு வழிகாட்டும் இலவச இதயச் சரிபார்ப்பு."),
        ("How it works", "यह कैसे काम करता है", "இது எப்படி வேலை செய்கிறது"),
        ("Each heartbeat pushes a little more blood into your fingertip, which absorbs a little more of the flash's light. The camera records those tiny brightness changes, and signal processing turns them into your heart rate.", "हर धड़कन उंगली के सिरे में थोड़ा और खून भेजती है, जो फ़्लैश की थोड़ी और रोशनी सोख लेता है। कैमरा चमक के इन छोटे बदलावों को रिकॉर्ड करता है, और सिग्नल प्रोसेसिंग उन्हें आपकी हृदय गति में बदलती है।", "ஒவ்வொரு துடிப்பும் விரல் நுனிக்குச் சற்று அதிக இரத்தத்தைத் தள்ளுகிறது; அது ஃபிளாஷ் ஒளியைச் சற்று அதிகம் உறிஞ்சுகிறது. கேமரா இந்த நுண்ணிய ஒளி மாற்றங்களைப் பதிவு செய்கிறது, சிக்னல் செயலாக்கம் அவற்றை இதயத் துடிப்பாக மாற்றுகிறது."),
        ("A small machine-learning model, trained only on your own readings and check-ins on this phone, learns what's usual for you. Nothing is uploaded.", "एक छोटा मशीन-लर्निंग मॉडल, जो केवल इसी फ़ोन पर आपकी रीडिंग और चेक-इन से सीखता है, समझता है कि आपके लिए क्या सामान्य है। कुछ भी अपलोड नहीं होता।", "இந்த ஃபோனில் உங்கள் அளவீடுகள் மற்றும் சரிபார்ப்புகளில் மட்டும் பயிற்சி பெறும் ஒரு சிறிய இயந்திரக் கற்றல் மாதிரி, உங்களுக்கு எது வழக்கம் என்று கற்றுக்கொள்கிறது. எதுவும் பதிவேற்றப்படாது."),
        ("Not a medical device", "चिकित्सा उपकरण नहीं", "மருத்துவச் சாதனம் அல்ல"),
        ("This app is for wellness and education. It is not FDA-approved, does not diagnose any condition, and never replaces a doctor.", "यह ऐप स्वास्थ्य जागरूकता और शिक्षा के लिए है। यह FDA-अनुमोदित नहीं है, किसी बीमारी का निदान नहीं करता, और डॉक्टर की जगह नहीं लेता।", "இந்தச் செயலி நலவாழ்வு மற்றும் கல்விக்கானது. இது FDA அங்கீகாரம் பெற்றதல்ல, எந்த நோயையும் கண்டறியாது, மருத்துவருக்கு மாற்றும் அல்ல."),
        ("Breathing", "साँस", "மூச்சு"),
        ("Slow breathing can help your heart settle. Pick one and follow the circle.", "धीमी साँस दिल को शांत करने में मदद कर सकती है। एक चुनें और गोले के साथ चलें।", "மெதுவான மூச்சு இதயத்தை அமைதிப்படுத்த உதவும். ஒன்றைத் தேர்ந்தெடுத்து வட்டத்தைப் பின்பற்றுங்கள்."),
        ("4-7-8 Breathing", "4-7-8 साँस", "4-7-8 மூச்சு"),
        ("Box Breathing", "बॉक्स साँस", "பெட்டி மூச்சு"),
        ("Coherent Breathing", "संतुलित साँस", "சீரான மூச்சு"),
        ("Calming", "शांत करने वाला", "அமைதிப்படுத்தும்"),
        ("Focus", "एकाग्रता", "கவனம்"),
        ("Slow and steady", "धीमा और स्थिर", "மெதுவாகவும் சீராகவும்"),
        ("Allow reminders", "याद दिलाने की अनुमति दें", "நினைவூட்டல்களை அனுமதி"),
        ("Morning heart check", "सुबह की हृदय जाँच", "காலை இதயச் சரிபார்ப்பு"),
        ("Time", "समय", "நேரம்"),
        ("Evening breathing", "शाम की साँस", "மாலை மூச்சுப் பயிற்சி"),
        ("Weekly insights", "साप्ताहिक जानकारी", "வாராந்திர நுண்ணறிவுகள்"),
        ("Cover the camera lens and the flash beside it with one fingertip. Your middle finger reaches most easily.", "एक उंगली के सिरे से कैमरा लेंस और उसके पास का फ़्लैश ढकें। बीच वाली उंगली सबसे आसानी से पहुँचती है।", "ஒரு விரல் நுனியால் கேமரா லென்ஸையும் அதன் அருகிலுள்ள ஃபிளாஷையும் மூடுங்கள். நடுவிரல் எளிதாக எட்டும்."),
        ("Rest it lightly. Pressing hard hides your pulse.", "हल्के से रखें। ज़ोर से दबाने पर नब्ज़ छिप जाती है।", "மெதுவாக வையுங்கள். அழுத்தமாக அழுத்தினால் நாடித்துடிப்பு மறைந்துவிடும்."),
        ("Sit still for 30 seconds. On the next screen, a circle turns bright red when your finger is in the right spot.", "30 सेकंड स्थिर बैठें। अगली स्क्रीन पर, उंगली सही जगह होने पर गोला चमकीला लाल हो जाता है।", "30 வினாடிகள் அசையாமல் அமருங்கள். அடுத்த திரையில், விரல் சரியான இடத்தில் இருந்தால் வட்டம் பிரகாசமான சிவப்பாக மாறும்."),
        ("Record your heart sound", "अपने दिल की आवाज़ रिकॉर्ड करें", "உங்கள் இதய ஒலியைப் பதிவு செய்யுங்கள்"),
        ("A 30-second recording you can play back or share with a doctor. The app records it; it doesn't diagnose it.", "30 सेकंड की रिकॉर्डिंग जिसे आप सुन सकते हैं या डॉक्टर के साथ साझा कर सकते हैं। ऐप इसे रिकॉर्ड करता है, निदान नहीं करता।", "மீண்டும் கேட்க அல்லது மருத்துவருடன் பகிர 30 வினாடி பதிவு. செயலி இதைப் பதிவு செய்கிறது; நோயறிதல் செய்யாது."),
        ("Find a quiet room.", "शांत कमरा चुनें।", "அமைதியான அறையைத் தேர்ந்தெடுங்கள்."),
        ("Press the bottom of the phone, where the microphone is, flat against your chest, just left of your breastbone.", "फ़ोन का निचला हिस्सा, जहाँ माइक्रोफ़ोन है, छाती की हड्डी के ठीक बाईं ओर सपाट दबाएँ।", "மைக்ரோஃபோன் உள்ள ஃபோனின் அடிப்பகுதியை மார்பெலும்பின் இடதுபுறம் தட்டையாக அழுத்துங்கள்."),
        ("Breathe normally and hold still. The phone buzzes when the 30 seconds are up.", "सामान्य साँस लें और स्थिर रहें। 30 सेकंड पूरे होने पर फ़ोन वाइब्रेट करेगा।", "இயல்பாக மூச்சு விட்டு அசையாமல் இருங்கள். 30 வினாடிகள் முடிந்ததும் ஃபோன் அதிரும்."),
        ("Start recording", "रिकॉर्डिंग शुरू करें", "பதிவைத் தொடங்கு"),
        ("Hold still and breathe normally.", "स्थिर रहें और सामान्य साँस लें।", "அசையாமல் இருந்து இயல்பாக மூச்சு விடுங்கள்."),
        ("Heart sound recorded", "दिल की आवाज़ रिकॉर्ड हो गई", "இதய ஒலி பதிவானது"),
        ("Listen back, keep it in your history, or share it with a doctor.", "इसे सुनें, इतिहास में रखें, या डॉक्टर के साथ साझा करें।", "மீண்டும் கேளுங்கள், வரலாற்றில் வைத்திருங்கள், அல்லது மருத்துவருடன் பகிருங்கள்."),
        ("This app records your heart sound but doesn't analyze or diagnose it. A doctor can listen to it for you.", "यह ऐप दिल की आवाज़ रिकॉर्ड करता है, पर उसका विश्लेषण या निदान नहीं करता। डॉक्टर इसे सुन सकते हैं।", "இந்தச் செயலி இதய ஒலியைப் பதிவு செய்கிறது, ஆனால் பகுப்பாய்வோ நோயறிதலோ செய்யாது. மருத்துவர் அதைக் கேட்கலாம்."),
        ("Save recording", "रिकॉर्डिंग सहेजें", "பதிவைச் சேமி"),
        ("Record again", "फिर से रिकॉर्ड करें", "மீண்டும் பதிவு செய்"),
    ]
}
