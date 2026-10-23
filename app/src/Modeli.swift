// Osnovni tipovi koje deli cela aplikacija.
import Foundation

enum StanjeAplikacije: Equatable {
    case mirno
    case snima
    case priprema
    case prepisuje
    case greska(String)

    var naslov: String {
        switch self {
        case .mirno: return "Spreman"
        case .snima: return "Snimam…"
        case .priprema: return "Pripremam model…"
        case .prepisuje: return "Prepisujem…"
        case .greska: return "Greška"
        }
    }

    var detalj: String {
        switch self {
        case .mirno: return "Drži Fn i govori. Pusti kada završiš."
        case .snima: return "Govori sada — pusti Fn da završiš."
        case .priprema: return "Model se učitava u memoriju, sačekaj trenutak."
        case .prepisuje: return "Pretvaram govor u tekst."
        case .greska(let poruka): return poruka
        }
    }

    var jeSnimanje: Bool {
        if case .snima = self { return true }
        return false
    }

    var jeZauzet: Bool {
        switch self {
        case .priprema, .prepisuje: return true
        default: return false
        }
    }
}

struct Zapis: Identifiable, Codable, Equatable {
    var id = UUID()
    var tekst: String
    var datum = Date()
    var trajanje: Double = 0
    var jezik: String = "auto"
}

struct Dozvole: Equatable {
    var mikrofon = false
    var pristupacnost = false
    var nadzorUnosa = false

    var sve: Bool { mikrofon && pristupacnost && nadzorUnosa }
}

struct Podesavanja: Codable, Equatable {
    var jezik = "auto"
    var automatskoLepljenje = true
    var zvuk = true
    var doterivanje = false
    var cuvajIstoriju = true
    /// Dnevna provera novih izdanja na GitHub-u (samo čitanje javnog spiska).
    var proveravajAzuriranja = true
    var model = Modeli.podrazumevani.id
    var provajderDoterivanja = ProvajderiDoterivanja.podrazumevani.id
    /// Model se pamti po servisu da promena servisa ne bi poslala pogrešan naziv.
    var modeliDoterivanja: [String: String] = [:]
    /// Adresa se koristi samo za servis „Drugi OpenAI-kompatibilni“.
    var adresaCustomDoterivanja = ""

    init() {}

    private enum CodingKeys: String, CodingKey {
        case jezik
        case automatskoLepljenje
        case zvuk
        case doterivanje
        case cuvajIstoriju
        case proveravajAzuriranja
        case model
        case provajderDoterivanja
        case modeliDoterivanja
        case adresaCustomDoterivanja
    }

    /// Rucno dekodiranje da stara podesavanja (bez polja `model`) ne puknu
    /// i da automatski izaberu model koji vec postoji na disku.
    init(from decoder: Decoder) throws {
        let kontejner = try decoder.container(keyedBy: CodingKeys.self)
        jezik = try kontejner.decodeIfPresent(String.self, forKey: .jezik) ?? "auto"
        automatskoLepljenje = try kontejner.decodeIfPresent(Bool.self, forKey: .automatskoLepljenje) ?? true
        zvuk = try kontejner.decodeIfPresent(Bool.self, forKey: .zvuk) ?? true
        doterivanje = try kontejner.decodeIfPresent(Bool.self, forKey: .doterivanje) ?? false
        cuvajIstoriju = try kontejner.decodeIfPresent(Bool.self, forKey: .cuvajIstoriju) ?? true
        proveravajAzuriranja = try kontejner.decodeIfPresent(Bool.self, forKey: .proveravajAzuriranja) ?? true
        model = try kontejner.decodeIfPresent(String.self, forKey: .model)
            ?? Modeli.nadjiPostojeci()?.id
            ?? Modeli.podrazumevani.id
        provajderDoterivanja = try kontejner.decodeIfPresent(String.self, forKey: .provajderDoterivanja)
            ?? ProvajderiDoterivanja.podrazumevani.id
        modeliDoterivanja = try kontejner.decodeIfPresent([String: String].self, forKey: .modeliDoterivanja)
            ?? [:]
        adresaCustomDoterivanja = try kontejner.decodeIfPresent(String.self, forKey: .adresaCustomDoterivanja)
            ?? ""
        if ProvajderiDoterivanja.nadji(provajderDoterivanja) == nil {
            provajderDoterivanja = ProvajderiDoterivanja.podrazumevani.id
        }
    }
}
