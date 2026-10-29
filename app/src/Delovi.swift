// Mali delovi od kojih se sklapa ceo interfejs.
import SwiftUI

enum Izgled {
    static let akcenat = Color(red: 0.36, green: 0.32, blue: 0.90)
    static let pozadina = LinearGradient(
        colors: [
            Color(nsColor: .windowBackgroundColor),
            Color(nsColor: .windowBackgroundColor).opacity(0.92),
            Izgled.akcenat.opacity(0.06),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct Kartica<Sadrzaj: View>: View {
    var naslov: String?
    var ikona: String?
    var bojaIkone: Color = Izgled.akcenat
    @ViewBuilder var sadrzaj: Sadrzaj

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let naslov {
                HStack(spacing: 8) {
                    Image(systemName: ikona ?? "circle")
                        .foregroundStyle(bojaIkone)
                    Text(naslov).font(.headline)
                }
            }
            sadrzaj
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

struct StatusnaTacka: View {
    let stanje: StanjeAplikacije

    private var boja: Color {
        switch stanje {
        case .mirno: return .green
        case .snima: return .red
        case .priprema, .prepisuje: return .orange
        case .greska: return .red
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(boja).frame(width: 7, height: 7)
            Text(stanje.naslov)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(boja.opacity(0.13)))
        .overlay(Capsule().stroke(boja.opacity(0.25), lineWidth: 1))
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
                .font(.system(size: 17))
                .foregroundStyle(dozvoljeno ? Color.green : Izgled.akcenat)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(naziv).font(.subheadline.weight(.medium))
                Text(opis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if dozvoljeno {
                Label("Dozvoljeno", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            } else {
                Button("Dozvoli", action: akcija)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Izgled.akcenat)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NaslovSekcije: View {
    let tekst: String
    let detalj: String?

    init(_ tekst: String, detalj: String? = nil) {
        self.tekst = tekst
        self.detalj = detalj
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(tekst).font(.title3.weight(.semibold))
            if let detalj {
                Text(detalj).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct InfoTraka: View {
    let tekst: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill").foregroundStyle(Izgled.akcenat)
            Text(tekst).font(.callout)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct GreskaKartica: View {
    let poruka: String
    let zatvori: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(poruka)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button("U redu", action: zatvori)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.09)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2), lineWidth: 1))
    }
}

struct AzuriranjeTraka: View {
    let verzija: String
    let trenutna: String
    let stavke: [String]
    let preuzmi: () -> Void
    let kasnije: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Izgled.akcenat)

            VStack(alignment: .leading, spacing: 4) {
                Text("Dostupna je verzija \(verzija)")
                    .font(.callout.weight(.semibold))
                Text("Imaš \(trenutna). Preuzmi novo izdanje sa GitHub-a.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !stavke.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Šta je novo:")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(Array(stavke.prefix(3).enumerated()), id: \.offset) { _, stavka in
                            Text("• \(stavka)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Button("Preuzmi", action: preuzmi)
                    .buttonStyle(.borderedProminent)
                    .tint(Izgled.akcenat)
                    .controlSize(.small)

                Button("Kasnije", action: kasnije)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Izgled.akcenat.opacity(0.09)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Izgled.akcenat.opacity(0.2), lineWidth: 1))
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
