// Istorija svih prepisa, sa pretragom i brisanjem.
import SwiftUI

struct PogledIstorija: View {
    @EnvironmentObject var app: AppStanje
    @State private var pretraga = ""
    @State private var potvrdiBrisanje = false

    private var filtrirano: [Zapis] {
        guard !pretraga.trimmingCharacters(in: .whitespaces).isEmpty else { return app.istorija }
        return app.istorija.filter { $0.tekst.localizedCaseInsensitiveContains(pretraga) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                NaslovSekcije("Istorija", detalj: "\(app.istorija.count) prepisa, čuvaju se samo na ovom Macu")

                Spacer()

                poljePretrage

                if !app.istorija.isEmpty {
                    Button {
                        potvrdiBrisanje = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .help("Obriši celu istoriju")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            if app.istorija.isEmpty {
                prazno
            } else if filtrirano.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 26))
                        .foregroundStyle(.secondary)
                    Text("Nema rezultata za „\(pretraga)”").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtrirano) { zapis in
                            red(zapis)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert("Obrisati celu istoriju?", isPresented: $potvrdiBrisanje) {
            Button("Obriši", role: .destructive) { app.obrisiIstoriju() }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Ova radnja se ne može poništiti.")
        }
    }

    private var poljePretrage: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Traži u istoriji", text: $pretraga)
                .textFieldStyle(.plain)
                .frame(width: 180)
            if !pretraga.isEmpty {
                Button {
                    pretraga = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
    }

    private var prazno: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.bubble")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Izgled.akcenat.opacity(0.7))
            Text("Još nema prepisa")
                .font(.title3.weight(.semibold))
            Text("Drži Fn i izgovori prvu rečenicu — ovde će se pojaviti.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func red(_ zapis: Zapis) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(zapis.tekst)
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(zapis.datum.formatted(date: .abbreviated, time: .shortened))
                    Text("·")
                    Text(trajanje(zapis.trajanje))
                    Text("·")
                    Text(jezik(zapis.jezik))
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Button {
                    app.kopiraj(zapis.tekst)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Kopiraj")

                Button {
                    app.obrisi(zapis)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Obriši")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .contextMenu {
            Button("Kopiraj") { app.kopiraj(zapis.tekst) }
            Button("Obriši", role: .destructive) { app.obrisi(zapis) }
        }
    }

    private func trajanje(_ sekunde: Double) -> String {
        if sekunde < 1 { return "kratko" }
        return String(format: "%.0f s", sekunde)
    }

    private func jezik(_ kod: String) -> String {
        switch kod {
        case "sr", "hr", "bs": return "srpski"
        case "en": return "engleski"
        default: return "automatski"
        }
    }
}
