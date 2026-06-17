import Foundation

let isItalian: Bool = {
    let code = Locale.current.language.languageCode?.identifier ?? "en"
    return code == "it"
}()

func L(_ it: String, _ en: String) -> String {
    isItalian ? it : en
}
