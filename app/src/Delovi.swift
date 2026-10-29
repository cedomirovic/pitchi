// Mali delovi od kojih se sklapa ceo interfejs.
import SwiftUI

/// Boje, zaobljenja i razmaci dizajna — jedno mesto za sve ekrane.
/// Plava je iz dizajna (#0A84FF), a podloge prate svetlu i tamnu temu sistema.
enum Izgled {
    static let akcenat = Color(red: 0.04, green: 0.52, blue: 1.00)
    static let akcenatTamni = Color(red: 0.00, green: 0.40, blue: 0.85)
    static let zelena = Color(red: 0.13, green: 0.66, blue: 0.35)
    static let narandzasta = Color(red: 0.96, green: 0.58, blue: 0.12)
    static let crvena = Color(red: 0.92, green: 0.26, blue: 0.21)

    static let pozadina = Color(nsColor: .windowBackgroundColor)
    static let kartica = Color(nsColor: .textBackgroundColor)
    static let meka = Color.primary.opacity(0.05)
    static let ivica = Color.primary.opacity(0.07)

    static let ugaoKartice: CGFloat = 14
    static let ugaoReda: CGFloat = 10
    static let unutrasnjiRazmak: CGFloat = 14

    /// Boje za grafikone i prstenaste podele, po redu.
    static let grafikoni: [Color] = [
        akcenat,
        Color(red: 0.42, green: 0.45, blue: 0.95),
        Color(red: 0.30, green: 0.72, blue: 0.68),
        Color(red: 0.96, green: 0.58, blue: 0.12),
        Color(red: 0.62, green: 0.66, blue: 0.72),
    ]

    static func bojaGrafikona(_ indeks: Int) -> Color {
        grafikoni[indeks % grafikoni.count]
    }
}

/// Bela kartica sa zaobljenim uglovima — osnovni blok svakog ekrana.
struct Kartica<Sadrzaj: View>: View {
    var naslov: String?
    var ikona: String?
    var detalj: String?
    var bojaIkone: Color = Izgled.akcenat
    @ViewBuilder var sadrzaj: Sadrzaj

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if naslov != nil || ikona != nil {
                HStack(spacing: 9) {
                    if let ikona {
                        Image(systemName: ikona)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(bojaIkone)
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(bojaIkone.opacity(0.11))
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let naslov {
                            Text(naslov)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        if let detalj {
                            Text(detalj)
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            sadrzaj
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .fill(Izgled.kartica)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .stroke(Izgled.ivica, lineWidth: 1)
        )
    }
}

/// Naslov strane: veliki naslov i sivi podnaslov, sa mestom za kontrolu desno.
struct ZaglavljeStrane<Trailing: View>: View {
    let naslov: String
    let detalj: String
    @ViewBuilder var dodatak: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(naslov)
                    .font(.system(size: 27, weight: .bold))
                Text(detalj)
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            dodatak
        }
    }
}

extension ZaglavljeStrane where Trailing == EmptyView {
    init(naslov: String, detalj: String) {
        self.init(naslov: naslov, detalj: detalj) { EmptyView() }
    }
}

/// Manji naslov grupe iznad kartice (npr. „Ponašanje aplikacije“).
struct NaslovGrupe: View {
    let tekst: String

    init(_ tekst: String) {
        self.tekst = tekst
    }

    var body: some View {
        Text(tekst)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 2)
    }
}

/// Grupa podešavanja: naslov iznad, jedna bela kartica sa redovima unutra.
struct SekcijaPodesavanja<Sadrzaj: View>: View {
    let naslov: String
    @ViewBuilder var sadrzaj: Sadrzaj

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            NaslovGrupe(naslov)
            VStack(spacing: 0) {
                sadrzaj
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                    .fill(Izgled.kartica)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                    .stroke(Izgled.ivica, lineWidth: 1)
            )
        }
    }
}

/// Jedan red u grupi podešavanja: ikona, naslov, opis i kontrola desno.
struct RedPodesavanja<Kontrola: View>: View {
    let ikona: String
    let naslov: String
    var opis: String?
    var prvi: Bool = false
    @ViewBuilder var kontrola: Kontrola

    var body: some View {
        VStack(spacing: 0) {
            if !prvi {
                Rectangle()
                    .fill(Izgled.ivica)
                    .frame(height: 1)
                    .padding(.leading, 52)
            }

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: ikona)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary.opacity(0.72))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(naslov)
                        .font(.system(size: 13, weight: .medium))
                    if let opis {
                        Text(opis)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 12)

                kontrola
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
    }
}

/// Prekidač u redu podešavanja, bez svog natpisa (natpis je u redu).
/// Crta se sam, pa u neaktivnom prozoru ostaje plave boje kao u dizajnu.
struct Prekidac: View {
    @Binding var ukljuceno: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.14)) {
                ukljuceno.toggle()
            }
        } label: {
            Capsule()
                .fill(ukljuceno ? Izgled.akcenat : Color.primary.opacity(0.16))
                .frame(width: 34, height: 20)
                .overlay(alignment: ukljuceno ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .padding(2)
                        .shadow(color: .black.opacity(0.16), radius: 1, y: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Uključi ili isključi")
        .accessibilityValue(ukljuceno ? "Uključeno" : "Isključeno")
    }
}

struct StatusnaTacka: View {
    let stanje: StanjeAplikacije

    private var boja: Color {
        switch stanje {
        case .mirno: return Izgled.zelena
        case .snima: return Izgled.crvena
        case .priprema, .prepisuje: return Izgled.narandzasta
        case .greska: return Izgled.crvena
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(boja).frame(width: 7, height: 7)
            Text(stanje.naslov)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(boja.opacity(0.13)))
        .overlay(Capsule().stroke(boja.opacity(0.22), lineWidth: 1))
    }
}

struct NivoTrake: View {
    let nivo: Float
    let aktivno: Bool
    var broj: Int = 22

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<broj, id: \.self) { i in
                let prag = Float(i) / Float(broj)
                let upaljeno = aktivno && nivo > prag
                Capsule()
                    .fill(upaljeno ? Izgled.akcenat : Color.primary.opacity(0.12))
                    .frame(width: 4, height: CGFloat(8 + (i % 6) * 4))
            }
        }
        .frame(height: 34)
        .animation(.easeOut(duration: 0.12), value: nivo)
    }
}

struct RedDozvole: View {
    let naziv: String
    let opis: String
    let ikona: String
    let dozvoljeno: Bool
    let akcija: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ikona)
                .font(.system(size: 14))
                .foregroundStyle(dozvoljeno ? Izgled.zelena : Izgled.akcenat)
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill((dozvoljeno ? Izgled.zelena : Izgled.akcenat).opacity(0.11))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(naziv).font(.system(size: 13, weight: .medium))
                Text(opis)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if dozvoljeno {
                Label("Dozvoljeno", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Izgled.zelena)
            } else {
                Button("Dozvoli", action: akcija)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Izgled.akcenat)
            }
        }
        .padding(.vertical, 3)
    }
}

/// Naslov unutar strane, manji od naslova strane (npr. „Često postavljena pitanja“).
struct NaslovSekcije: View {
    let tekst: String
    let detalj: String?

    init(_ tekst: String, detalj: String? = nil) {
        self.tekst = tekst
        self.detalj = detalj
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(tekst).font(.system(size: 15, weight: .semibold))
            if let detalj {
                Text(detalj).font(.system(size: 11.5)).foregroundStyle(.secondary)
            }
        }
    }
}

struct InfoTraka: View {
    let tekst: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill").foregroundStyle(Izgled.akcenat)
            Text(tekst).font(.system(size: 12))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 9)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Izgled.ivica).frame(height: 1)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct GreskaKartica: View {
    let poruka: String
    let zatvori: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Izgled.crvena)
            Text(poruka)
                .font(.system(size: 12))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button("U redu", action: zatvori)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoReda, style: .continuous)
                .fill(Izgled.crvena.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoReda, style: .continuous)
                .stroke(Izgled.crvena.opacity(0.18), lineWidth: 1)
        )
    }
}

/// Traka na dnu prozora o novom izdanju — jedna linija, da ne pomera strane.
struct AzuriranjeTraka: View {
    let verzija: String
    let trenutna: String
    let stavke: [String]
    let preuzmi: () -> Void
    let pogledaj: () -> Void
    let kasnije: () -> Void

    /// Prve dve stavke iz opisa izdanja, spojene u jednu rečenicu.
    private var sazetak: String? {
        guard !stavke.isEmpty else { return nil }
        let kratke = stavke.prefix(2).joined(separator: " · ")
        return kratke
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Izgled.akcenat)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text("Dostupna je verzija \(verzija)")
                        .font(.system(size: 11.5, weight: .semibold))
                    Text("· imaš \(trenutna)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                if let sazetak {
                    Text(sazetak)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("Detalji su u Podešavanjima → Ažuriranja.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Button("Šta je novo", action: pogledaj)
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                .foregroundStyle(Izgled.akcenat)

            // Dugme se crta ručno: sistemsko obojeno dugme u neaktivnom
            // prozoru izgleda sivo, a ovako je uvek plavo kao u dizajnu.
            Button(action: preuzmi) {
                Text("Preuzmi")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Izgled.akcenat)
                    )
            }
            .buttonStyle(.plain)

            Button {
                kasnije()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help("Kasnije")
            .accessibilityLabel("Prikaži kasnije")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Izgled.akcenat.opacity(0.07))
        .overlay(alignment: .top) {
            Rectangle().fill(Izgled.akcenat.opacity(0.14)).frame(height: 1)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct DugmeKopiraj: View {
    let tekst: String
    let akcija: () -> Void

    var body: some View {
        Button(action: akcija) {
            Image(systemName: "doc.on.doc")
        }
        .buttonStyle(.borderless)
        .help("Kopiraj u klipbord")
    }
}

/// Velika brojka sa natpisom i opcionom promenom — kartice na vrhu statistike.
struct BrojKartica: View {
    let naslov: String
    let vrednost: String
    let ikona: String
    var jedinica: String?
    var promena: Double?
    var opisPromene: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: ikona)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Izgled.akcenat)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Izgled.akcenat.opacity(0.10)))

                Text(naslov)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(vrednost)
                    .font(.system(size: 25, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let jedinica {
                    Text(jedinica)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let promena {
                HStack(spacing: 3) {
                    Image(systemName: promena < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(promena < 0 ? "" : "+")\(Int(promena.rounded()))%")
                        .font(.system(size: 10.5, weight: .semibold))
                    if let opisPromene {
                        Text(opisPromene)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(promena < 0 ? Izgled.crvena : Izgled.zelena)
            } else if let opisPromene {
                Text(opisPromene)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .fill(Izgled.kartica)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Izgled.ugaoKartice, style: .continuous)
                .stroke(Izgled.ivica, lineWidth: 1)
        )
    }
}
