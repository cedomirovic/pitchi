// Mali plutajući prozor koji pokazuje da Diktator snima — i van glavnog prozora.
import SwiftUI

struct HudPogled: View {
    @EnvironmentObject var app: AppStanje

    private var boja: Color {
        switch app.stanje {
        case .snima: return .red
        case .priprema, .prepisuje: return .orange
        default: return Izgled.akcenat
        }
    }

    private var ikona: String {
        switch app.stanje {
        case .snima: return "waveform"
        case .priprema, .prepisuje: return "sparkles"
        default: return "mic.fill"
        }
    }

    private var vreme: String {
        String(format: "%d:%02d", app.sekunde / 60, app.sekunde % 60)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(boja.opacity(0.18)).frame(width: 38, height: 38)
                if app.stanje.jeZauzet {
                    ProgressView().controlSize(.small).tint(boja)
                } else {
                    Image(systemName: ikona)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(boja)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.stanje.naslov)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                Text(podnaslov)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if app.stanje.jeSnimanje {
                NivoTrake(nivo: app.nivo, aktivno: true, broj: 7)
                Text(vreme)
                    .font(.system(.caption, design: .monospaced).weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 300, height: 62)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 14, y: 5)
        .padding(20)
    }

    private var podnaslov: String {
        switch app.stanje {
        case .snima:
            return app.izabranaPrecica.jePrekidac
                ? "Pritisni \(app.nazivPrecice) ponovo da završiš"
                : "Pusti \(app.nazivPrecice) kada završiš"
        case .priprema: return "Učitavam model…"
        case .prepisuje: return "Pretvaram govor u tekst…"
        default: return "Diktator"
        }
    }
}
