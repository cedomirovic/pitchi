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

    func detalj(precica: String = "Fn", prekidac: Bool = false) -> String {
        switch self {
        case .mirno:
            return prekidac
                ? "Pritisni \(precica) da počneš, ponovo da završiš."
                : "Drži \(precica) i govori. Pusti kada završiš."
        case .snima:
            return prekidac
                ? "Govori sada — pritisni \(precica) ponovo da završiš."
                : "Govori sada — pusti \(precica) da završiš."
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

/// Taster ili kombinacija za diktiranje. Većina prečica se drži dok se
/// govori; Fn + Space je prekidač (pritisni za početak, ponovo za kraj).
/// Desni modifikatori su bezbedniji od levih jer se levi često koriste u
/// prečicama drugih aplikacija.
enum Precica: String, CaseIterable, Identifiable {
    case fn
    case fnSpace = "fn-space"
    case desniOption = "desni-option"
    case desniCommand = "desni-command"
    case desniControl = "desni-control"
    case desniShift = "desni-shift"
    case f13
    case f14
    case f15
    case f16
    case f17
    case f18
    case f19

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .fn: return "Fn"
        case .fnSpace: return "Fn + Space"
        case .desniOption: return "Desni Option"
        case .desniCommand: return "Desni Command"
        case .desniControl: return "Desni Control"
        case .desniShift: return "Desni Shift"
        case .f13: return "F13"
        case .f14: return "F14"
        case .f15: return "F15"
        case .f16: return "F16"
        case .f17: return "F17"
        case .f18: return "F18"
        case .f19: return "F19"
        }
    }

    var simbol: String {
        switch self {
        case .fn: return "Fn"
        // Znak „␣“ nema u sistemskom fontu pa se u uskoj znački iseče,
        // zato se kombinacija ispisuje rečima.
        case .fnSpace: return "Fn + Space"
        case .desniOption: return "⌥"
        case .desniCommand: return "⌘"
        case .desniControl: return "⌃"
        case .desniShift: return "⇧"
        default: return naziv
        }
    }

    var etiketa: String {
        if self == .fnSpace { return naziv }
        return naziv == simbol ? naziv : "\(naziv)  \(simbol)"
    }

    /// macOS virtual keycode za taster.
    var kod: Int64 {
        switch self {
        case .fn: return 63
        case .fnSpace: return 49
        case .desniOption: return 61
        case .desniCommand: return 54
        case .desniControl: return 62
        case .desniShift: return 60
        case .f13: return 105
        case .f14: return 107
        case .f15: return 113
        case .f16: return 106
        case .f17: return 64
        case .f18: return 79
        case .f19: return 80
        }
    }

    var jeModifikator: Bool {
        switch self {
        case .fn, .desniOption, .desniCommand, .desniControl, .desniShift:
            return true
        default:
            return false
        }
    }

    /// Fn + Space radi kao prekidač, ne kao taster koji se drži.
    var jePrekidac: Bool { self == .fnSpace }

    var uputstvo: String {
        if jePrekidac {
            return "Pritisni \(naziv) da počneš, ponovo da završiš."
        }
        return "Drži izabrani taster dok govoriš, pusti ga da završiš."
    }

    var kratkoUputstvo: String {
        if jePrekidac {
            return "Diktator — pritisni \(naziv) da snimiš"
        }
        return "Diktator — drži \(naziv) i govori"
    }

    static func iz(_ id: String) -> Precica {
        Precica(rawValue: id) ?? .fn
    }
}

/// Koliko dugo model ostaje u memoriji posle prepisa.
enum OslobadjanjeModela: String, CaseIterable, Identifiable {
    case odmah
    case jedan
    case pet
    case petnaest
    case trideset
    case nikad

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .odmah: return "Odmah posle prepisa"
        case .jedan: return "Posle 1 minuta"
        case .pet: return "Posle 5 minuta"
        case .petnaest: return "Posle 15 minuta"
        case .trideset: return "Posle 30 minuta"
        case .nikad: return "Nikad"
        }
    }

    /// Broj sekundi za tajmer; `nil` znači da se model ne oslobađa automatski.
    var sekunde: TimeInterval? {
        switch self {
        case .odmah: return 0
        case .jedan: return 60
        case .pet: return 300
        case .petnaest: return 900
        case .trideset: return 1800
        case .nikad: return nil
        }
    }

    var opis: String {
        switch self {
        case .odmah:
            return "Model se oslobađa odmah posle prepisa — najmanje memorije, ali se sledeći prepis sporije učitava."
        case .jedan:
            return "Model se oslobađa posle 1 minuta mirovanja."
        case .pet:
            return "Model se oslobađa posle 5 minuta mirovanja — podrazumevano."
        case .petnaest:
            return "Model se oslobađa posle 15 minuta mirovanja."
        case .trideset:
            return "Model se oslobađa posle 30 minuta mirovanja."
        case .nikad:
            return "Model ostaje u memoriji do ručnog oslobađanja ili zatvaranja aplikacije."
        }
    }

    static func iz(_ id: String) -> OslobadjanjeModela {
        OslobadjanjeModela(rawValue: id) ?? .pet
    }
}

/// Brzina i tačnost prepisa. Štedljivi režim koristi greedy dekodiranje i
/// troši znatno manje RAM-a od beam search-a.
enum RezimPrepisa: String, CaseIterable, Identifiable {
    case kvalitet
    case stedljivo

    var id: String { rawValue }

    var naziv: String {
        switch self {
        case .kvalitet: return "Najbolji kvalitet"
        case .stedljivo: return "Manje memorije"
        }
    }

    var opis: String {
        switch self {
        case .kvalitet:
            return "Beam search sa 5 kandidata — tačniji na težem snimku, troši više RAM-a."
        case .stedljivo:
            return "Greedy dekodiranje — oko 400 MB manje RAM-a i brži prepis, uz moguće sitne razlike u tekstu."
        }
    }

    static func iz(_ id: String) -> RezimPrepisa {
        RezimPrepisa(rawValue: id) ?? .kvalitet
    }
}

struct Podesavanja: Codable, Equatable {
    var jezik = "auto"
    var precica = Precica.fn.rawValue
    var oslobadjanjeModela = OslobadjanjeModela.pet.rawValue
    /// Novi korisnici dobijaju štedljivi režim; stara podešavanja bez ovog
    /// polja zadržavaju beam search (kvalitet) da se ponašanje ne promeni.
    var rezimPrepisa = RezimPrepisa.stedljivo.rawValue
    var automatskoLepljenje = true
    var zvuk = true
    var doterivanje = false
    var cuvajIstoriju = true
    /// Dnevna provera novih izdanja na GitHub-u (samo čitanje javnog spiska).
    var proveravajAzuriranja = true
    var model = Modeli.podrazumevani.id
    /// Brzi režim: Turbo model, duže držanje u RAM-u i učitavanje unapred.
    var brziRezim = false
    /// Učitaj model odmah po pokretanju da prvi diktat ne čeka.
    var unapredUcitajModel = false
    var provajderDoterivanja = ProvajderiDoterivanja.podrazumevani.id
    /// Model se pamti po servisu da promena servisa ne bi poslala pogrešan naziv.
    var modeliDoterivanja: [String: String] = [:]
    /// Adresa se koristi samo za servis „Drugi OpenAI-kompatibilni“.
    var adresaCustomDoterivanja = ""

    init() {}

    private enum CodingKeys: String, CodingKey {
        case jezik
        case precica
        case oslobadjanjeModela
        case rezimPrepisa
        case automatskoLepljenje
        case zvuk
        case doterivanje
        case cuvajIstoriju
        case proveravajAzuriranja
        case model
        case brziRezim
        case unapredUcitajModel
        case provajderDoterivanja
        case modeliDoterivanja
        case adresaCustomDoterivanja
    }

    /// Rucno dekodiranje da stara podesavanja (bez polja `model`) ne puknu
    /// i da automatski izaberu model koji vec postoji na disku.
    init(from decoder: Decoder) throws {
        let kontejner = try decoder.container(keyedBy: CodingKeys.self)
        jezik = try kontejner.decodeIfPresent(String.self, forKey: .jezik) ?? "auto"
        precica = try kontejner.decodeIfPresent(String.self, forKey: .precica) ?? Precica.fn.rawValue
        if Precica(rawValue: precica) == nil {
            precica = Precica.fn.rawValue
        }
        oslobadjanjeModela = try kontejner.decodeIfPresent(String.self, forKey: .oslobadjanjeModela)
            ?? OslobadjanjeModela.pet.rawValue
        if OslobadjanjeModela(rawValue: oslobadjanjeModela) == nil {
            oslobadjanjeModela = OslobadjanjeModela.pet.rawValue
        }
        rezimPrepisa = try kontejner.decodeIfPresent(String.self, forKey: .rezimPrepisa)
            ?? RezimPrepisa.kvalitet.rawValue
        if RezimPrepisa(rawValue: rezimPrepisa) == nil {
            rezimPrepisa = RezimPrepisa.kvalitet.rawValue
        }
        automatskoLepljenje = try kontejner.decodeIfPresent(Bool.self, forKey: .automatskoLepljenje) ?? true
        zvuk = try kontejner.decodeIfPresent(Bool.self, forKey: .zvuk) ?? true
        doterivanje = try kontejner.decodeIfPresent(Bool.self, forKey: .doterivanje) ?? false
        cuvajIstoriju = try kontejner.decodeIfPresent(Bool.self, forKey: .cuvajIstoriju) ?? true
        proveravajAzuriranja = try kontejner.decodeIfPresent(Bool.self, forKey: .proveravajAzuriranja) ?? true
        model = try kontejner.decodeIfPresent(String.self, forKey: .model)
            ?? Modeli.nadjiPostojeci()?.id
            ?? Modeli.podrazumevani.id
        brziRezim = try kontejner.decodeIfPresent(Bool.self, forKey: .brziRezim) ?? false
        unapredUcitajModel = try kontejner.decodeIfPresent(Bool.self, forKey: .unapredUcitajModel) ?? false
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
