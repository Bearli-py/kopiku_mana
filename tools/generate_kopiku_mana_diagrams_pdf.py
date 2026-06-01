#!/usr/bin/env python3
"""Generate a PDF document for Kopiku Mana use case and DFD diagrams."""

from __future__ import annotations

from pathlib import Path
from textwrap import wrap

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import cm
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "kopiku_mana_usecase_dfd.pdf"

BROWN = colors.HexColor("#6F4E37")
DARK = colors.HexColor("#2F211B")
LIGHT_BROWN = colors.HexColor("#F6EFE8")
CREAM = colors.HexColor("#FFF8EF")
GOLD = colors.HexColor("#D59A2F")
GREEN = colors.HexColor("#2E7D32")
BLUE = colors.HexColor("#1565C0")
GRAY = colors.HexColor("#5F5F5F")
LIGHT_GRAY = colors.HexColor("#F2F2F2")


class PdfDoc:
    def __init__(self, path: Path):
        self.path = path
        self.c = canvas.Canvas(str(path), pagesize=A4, pageCompression=0)
        self.page_no = 0
        self.width, self.height = A4

    def set_page(self, page_size=A4):
        self.width, self.height = page_size
        self.c.setPageSize(page_size)
        self.page_no += 1

    def new_page(self, page_size=A4, title: str | None = None):
        if self.page_no:
            self.c.showPage()
        self.set_page(page_size)
        if title:
            self.header(title)

    def header(self, title: str):
        self.c.setFillColor(BROWN)
        self.c.rect(0, self.height - 1.55 * cm, self.width, 1.55 * cm, fill=1, stroke=0)
        self.c.setFillColor(colors.white)
        self.c.setFont("Helvetica-Bold", 13)
        self.c.drawString(1.35 * cm, self.height - 1.0 * cm, title)
        self.c.setFillColor(colors.white)
        self.c.setFont("Helvetica", 8)
        self.c.drawRightString(
            self.width - 1.35 * cm,
            self.height - 1.0 * cm,
            "Kopiku Mana - Use Case & DFD",
        )

    def footer(self):
        self.c.setStrokeColor(colors.HexColor("#DDDDDD"))
        self.c.line(1.35 * cm, 1.2 * cm, self.width - 1.35 * cm, 1.2 * cm)
        self.c.setFillColor(GRAY)
        self.c.setFont("Helvetica", 8)
        self.c.drawString(1.35 * cm, 0.75 * cm, "Disusun berdasarkan alur aplikasi Flutter Kopiku Mana.")
        self.c.drawRightString(self.width - 1.35 * cm, 0.75 * cm, f"Halaman {self.page_no}")

    def save(self):
        self.c.save()

    def finish_page(self):
        self.footer()

    def text(self, x, y, text, size=10, color=DARK, bold=False, align="left"):
        self.c.setFillColor(color)
        self.c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
        if align == "center":
            self.c.drawCentredString(x, y, text)
        elif align == "right":
            self.c.drawRightString(x, y, text)
        else:
            self.c.drawString(x, y, text)

    def para(self, x, y, text, width, size=9, leading=12, color=DARK, bold=False):
        line_chars = max(20, int(width / (size * 0.48)))
        self.c.setFillColor(color)
        self.c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
        for line in wrap(text, line_chars):
            self.c.drawString(x, y, line)
            y -= leading
        return y

    def bullet_list(self, x, y, items, width, size=9, leading=12):
        for item in items:
            self.text(x, y, "-", size=size, color=BROWN, bold=True)
            y = self.para(x + 12, y, item, width - 12, size=size, leading=leading)
            y -= 3
        return y

    def box(self, x, y, w, h, title, body=None, fill=CREAM, stroke=BROWN, radius=8, title_size=9):
        self.c.setFillColor(fill)
        self.c.setStrokeColor(stroke)
        self.c.setLineWidth(1)
        self.c.roundRect(x, y, w, h, radius, fill=1, stroke=1)
        self.text(x + 8, y + h - 16, title, size=title_size, bold=True, color=DARK)
        if body:
            self.para(x + 8, y + h - 31, body, w - 16, size=7.5, leading=9, color=GRAY)

    def ellipse(self, x, y, w, h, text, fill=colors.white, stroke=BROWN, size=8):
        self.c.setFillColor(fill)
        self.c.setStrokeColor(stroke)
        self.c.setLineWidth(1)
        self.c.ellipse(x, y, x + w, y + h, fill=1, stroke=1)
        lines = wrap(text, max(10, int(w / (size * 0.48))))
        start_y = y + h / 2 + (len(lines) - 1) * (size + 1) / 2 - 3
        for idx, line in enumerate(lines):
            self.text(x + w / 2, start_y - idx * (size + 1), line, size=size, align="center")

    def process_circle(self, x, y, r, title, body=None):
        self.c.setFillColor(colors.HexColor("#BBD7F0"))
        self.c.setStrokeColor(DARK)
        self.c.setLineWidth(1)
        self.c.circle(x, y, r, fill=1, stroke=1)
        title_lines = wrap(title, 14)
        start_y = y + 8 + (len(title_lines) - 1) * 4
        for idx, line in enumerate(title_lines):
            self.text(x, start_y - idx * 9, line, size=7, bold=True, align="center")
        if body:
            for idx, line in enumerate(wrap(body, 16)[:2]):
                self.text(x, y - 12 - idx * 8, line, size=6, color=GRAY, align="center")

    def datastore(self, x, y, w, h, title, body):
        self.c.setFillColor(colors.white)
        self.c.setStrokeColor(BLUE)
        self.c.rect(x, y, w, h, fill=1, stroke=1)
        self.c.line(x + 7, y, x + 7, y + h)
        self.text(x + 13, y + h - 14, title, size=8, bold=True, color=BLUE)
        self.para(x + 13, y + h - 26, body, w - 18, size=6.8, leading=8, color=GRAY)

    def arrow(self, x1, y1, x2, y2, label="", color=GRAY, size=6.8):
        self.c.setStrokeColor(color)
        self.c.setFillColor(color)
        self.c.setLineWidth(0.8)
        self.c.line(x1, y1, x2, y2)
        dx, dy = x2 - x1, y2 - y1
        length = max((dx * dx + dy * dy) ** 0.5, 0.1)
        ux, uy = dx / length, dy / length
        px, py = -uy, ux
        arrow_len = 7
        arrow_w = 3.5
        points = [
            (x2, y2),
            (x2 - arrow_len * ux + arrow_w * px, y2 - arrow_len * uy + arrow_w * py),
            (x2 - arrow_len * ux - arrow_w * px, y2 - arrow_len * uy - arrow_w * py),
        ]
        path = self.c.beginPath()
        path.moveTo(*points[0])
        path.lineTo(*points[1])
        path.lineTo(*points[2])
        path.close()
        self.c.drawPath(path, fill=1, stroke=0)
        if label:
            mx, my = (x1 + x2) / 2, (y1 + y2) / 2
            self.c.setFillColor(colors.white)
            text_w = self.c.stringWidth(label, "Helvetica", size) + 6
            self.c.rect(mx - text_w / 2, my - 4, text_w, 10, fill=1, stroke=0)
            self.text(mx, my - 1, label, size=size, color=color, align="center")

    def dashed_arrow(self, x1, y1, x2, y2, label="", color=GRAY, size=6.2):
        self.c.setDash(4, 3)
        self.arrow(x1, y1, x2, y2, label=label, color=color, size=size)
        self.c.setDash()

    def actor(self, x, y, label):
        self.c.setStrokeColor(DARK)
        self.c.setFillColor(DARK)
        self.c.circle(x, y + 32, 8, fill=0, stroke=1)
        self.c.line(x, y + 24, x, y + 2)
        self.c.line(x - 16, y + 15, x + 16, y + 15)
        self.c.line(x, y + 2, x - 13, y - 14)
        self.c.line(x, y + 2, x + 13, y - 14)
        for idx, line in enumerate(wrap(label, 14)):
            self.text(x, y - 28 - idx * 9, line, size=8, align="center", bold=True)

    def table(self, x, y, col_widths, rows, row_h=28, font_size=7.3, header=True):
        table_w = sum(col_widths)
        for r_idx, row in enumerate(rows):
            h = row_h
            self.c.setFillColor(LIGHT_BROWN if r_idx == 0 and header else colors.white)
            self.c.setStrokeColor(colors.HexColor("#D6D0CA"))
            self.c.rect(x, y - h, table_w, h, fill=1, stroke=1)
            cur_x = x
            for c_idx, cell in enumerate(row):
                self.c.setStrokeColor(colors.HexColor("#D6D0CA"))
                self.c.line(cur_x, y - h, cur_x, y)
                self.para(
                    cur_x + 4,
                    y - 11,
                    str(cell),
                    col_widths[c_idx] - 8,
                    size=font_size,
                    leading=8,
                    bold=(r_idx == 0 and header),
                    color=DARK if r_idx == 0 and header else GRAY,
                )
                cur_x += col_widths[c_idx]
            self.c.line(x + table_w, y - h, x + table_w, y)
            y -= h
        return y


def title_page(doc: PdfDoc):
    doc.new_page(A4)
    doc.c.setFillColor(BROWN)
    doc.c.rect(0, 0, doc.width, doc.height, fill=1, stroke=0)
    doc.c.setFillColor(colors.HexColor("#8B674F"))
    doc.c.circle(doc.width - 2.5 * cm, doc.height - 2.4 * cm, 2.8 * cm, fill=1, stroke=0)
    doc.c.setFillColor(colors.HexColor("#4E342E"))
    doc.c.circle(1.6 * cm, 1.4 * cm, 3.3 * cm, fill=1, stroke=0)
    doc.text(doc.width / 2, doc.height - 5.1 * cm, "KOPIKU MANA", size=28, color=colors.white, bold=True, align="center")
    doc.text(doc.width / 2, doc.height - 6.2 * cm, "Use Case Diagram, DFD Level 0, dan DFD Level 1", size=15, color=colors.white, align="center")
    doc.text(doc.width / 2, doc.height - 7.1 * cm, "Aplikasi Rekomendasi Cafe Wilayah Tapal Kuda", size=11, color=colors.HexColor("#F6E6D5"), align="center")
    y = doc.height - 9.1 * cm
    doc.box(3.2 * cm, y - 3.3 * cm, doc.width - 6.4 * cm, 3.3 * cm, "Isi Dokumen", fill=colors.white, stroke=colors.white)
    doc.bullet_list(
        3.7 * cm,
        y - 1.0 * cm,
        [
            "Use case diagram untuk relasi aktor dan fitur utama aplikasi.",
            "DFD level 0 untuk konteks sistem dan aliran data eksternal.",
            "DFD level 1 untuk rincian proses, data store, dan alur sistem.",
            "Deskripsi penjelasan berbahasa Indonesia sesuai alur aplikasi.",
        ],
        doc.width - 7.4 * cm,
        size=9,
    )
    doc.text(doc.width / 2, 2.7 * cm, "Disusun otomatis dari alur aplikasi Flutter saat ini", size=9, color=colors.white, align="center")
    doc.finish_page()


def overview_page(doc: PdfDoc):
    doc.new_page(A4, "1. Gambaran Sistem")
    y = doc.height - 2.3 * cm
    y = doc.para(
        1.35 * cm,
        y,
        "Kopiku Mana adalah aplikasi rekomendasi cafe di wilayah Tapal Kuda. Pengguna dapat login, mencari cafe, melihat detail cafe, menyimpan wishlist, menulis ulasan, mengumpulkan poin, memakai referral, melakukan top up poin, dan menukar poin untuk akses premium.",
        doc.width - 2.7 * cm,
        size=10,
        leading=14,
    )
    y -= 12
    doc.text(1.35 * cm, y, "Aktor dan Sistem Eksternal", size=12, bold=True, color=BROWN)
    y -= 12
    rows = [
        ["Aktor/Sistem", "Peran"],
        ["Pengguna", "Mencari cafe, melihat detail, wishlist, review, profil, referral, premium, top up."],
        ["Pengguna Baru", "Registrasi akun dan dapat memakai kode referral."],
        ["Admin Kopiku Mana", "Mengelola data cafe, kurasi top pick/hidden gems, dan status sponsor."],
        ["Mitra Cafe", "Mengajukan kerja sama sponsor melalui email."],
        ["Firebase Auth/Firestore", "Autentikasi dan penyimpanan data utama aplikasi."],
        ["Geolocator/GPS", "Memberikan koordinat untuk rekomendasi cafe terdekat."],
        ["ImgBB", "Menyimpan foto profil dan foto ulasan."],
        ["Backend Railway/Midtrans", "Membuat transaksi top up dan pembayaran."],
        ["SharedPreferences", "Menyimpan notifikasi lokal dan timestamp kunjungan."],
    ]
    doc.table(1.35 * cm, y, [4.2 * cm, doc.width - 6.9 * cm], rows, row_h=29, font_size=7.6)
    doc.finish_page()


def use_case_diagram_page(doc: PdfDoc):
    doc.new_page(landscape(A4), "2. Use Case Diagram")
    w, h = doc.width, doc.height
    boundary = (235, 55, 360, 455)
    doc.c.setFillColor(colors.white)
    doc.c.setStrokeColor(BROWN)
    doc.c.roundRect(*boundary, 10, fill=1, stroke=1)
    doc.text(boundary[0] + boundary[2] / 2, boundary[1] + boundary[3] - 19, "Sistem Aplikasi Kopiku Mana", size=12, bold=True, color=BROWN, align="center")

    actors = {
        "Pengguna": (92, 320),
        "Mitra Cafe": (92, 92),
        "Admin": (720, 100),
    }
    for label, (x, y) in actors.items():
        doc.actor(x, y, label)

    services = [
        ("Firebase Auth", 646, 423),
        ("Cloud Firestore", 646, 376),
        ("GPS / Geolocator", 646, 275),
        ("ImgBB", 646, 202),
        ("Backend Railway / Midtrans", 646, 128),
    ]
    for title, x, y in services:
        doc.box(x, y, 138, 34, title, fill=colors.HexColor("#EAF4EA"), stroke=GREEN, radius=2, title_size=7.2)

    use_cases = [
        ("Login", 345, 458, colors.white),
        ("Registrasi", 345, 428, colors.white),
        ("Kelola Profil", 345, 398, colors.white),
        ("Cari & Filter Cafe", 345, 360, colors.white),
        ("Lihat Cafe Terdekat", 345, 330, colors.white),
        ("Lihat Detail Cafe", 345, 300, colors.white),
        ("Tulis Review + Foto", 345, 262, colors.white),
        ("Wishlist Cafe", 345, 232, colors.white),
        ("Top Up Poin", 345, 202, colors.white),
        ("Referral", 345, 172, colors.white),
        ("Upgrade Premium", 345, 142, colors.HexColor("#FFF2C2")),
        ("Akses Hidden Gems", 345, 112, colors.HexColor("#FFF2C2")),
        ("Wishlist Unlimited", 345, 82, colors.HexColor("#FFF2C2")),
        ("Badge Premium", 345, 52, colors.HexColor("#FFF2C2")),
        ("Validasi Referral", 520, 428, colors.HexColor("#F5FAFF"), 96),
        ("Baca Data Cafe", 520, 360, colors.HexColor("#F5FAFF"), 96),
        ("Baca Review", 520, 300, colors.HexColor("#F5FAFF"), 96),
        ("Upload Foto", 520, 262, colors.HexColor("#F5FAFF"), 96),
        ("Proses Pembayaran", 520, 202, colors.HexColor("#F5FAFF"), 96),
        ("Cek Saldo Poin", 520, 142, colors.HexColor("#F5FAFF"), 96),
        ("Ajukan Sponsor", 497, 82, colors.white),
        ("Kelola Data Cafe", 497, 52, colors.white),
    ]
    centers = {}
    for item in use_cases:
        name, x, y, fill = item[:4]
        use_case_w = item[4] if len(item) > 4 else 150
        doc.ellipse(x, y, use_case_w, 24, name, fill=fill, stroke=BROWN, size=7)
        centers[name] = (x + use_case_w / 2, y + 12)

    # Aktor utama ke use case. Dibuat tipis agar tidak terlalu ramai.
    user_cases = [
        "Login", "Registrasi", "Kelola Profil", "Cari & Filter Cafe", "Lihat Cafe Terdekat",
        "Lihat Detail Cafe", "Tulis Review + Foto", "Wishlist Cafe", "Top Up Poin",
        "Referral", "Upgrade Premium", "Akses Hidden Gems", "Wishlist Unlimited", "Badge Premium",
    ]
    for case in user_cases:
        cx, cy = centers[case]
        doc.arrow(120, 336, cx - 75, cy, color=colors.HexColor("#9A9A9A"))
    doc.arrow(120, 108, centers["Ajukan Sponsor"][0] - 75, centers["Ajukan Sponsor"][1], label="kerja sama", color=GRAY)
    doc.arrow(696, 116, centers["Kelola Data Cafe"][0] + 75, centers["Kelola Data Cafe"][1], label="kelola", color=GRAY)

    # Layanan eksternal yang dipakai fitur.
    doc.arrow(495, 470, 646, 440, label="auth", color=GREEN)
    doc.arrow(495, 440, 646, 440, color=GREEN)
    doc.arrow(495, 410, 646, 392, label="profil", color=GREEN)
    doc.arrow(495, 372, 646, 392, label="data cafe", color=GREEN)
    doc.arrow(495, 312, 646, 392, label="detail/review", color=GREEN)
    doc.arrow(495, 274, 646, 219, label="foto", color=GREEN)
    doc.arrow(495, 342, 646, 292, label="lokasi", color=GREEN)
    doc.arrow(495, 214, 646, 145, label="payment", color=GREEN)
    doc.arrow(495, 184, 646, 392, label="poin", color=GREEN)
    doc.arrow(572, 94, 646, 392, label="sponsor", color=GREEN)

    # Relasi UML antar-use-case.
    include_color = colors.HexColor("#2458A6")
    extend_color = colors.HexColor("#B14A3A")
    doc.dashed_arrow(495, 440, 520, 440, label="<<include>>", color=include_color)
    doc.dashed_arrow(495, 372, 520, 372, label="<<include>>", color=include_color)
    doc.dashed_arrow(495, 312, 520, 312, label="<<include>>", color=include_color)
    doc.dashed_arrow(495, 214, 520, 214, label="<<include>>", color=include_color)
    doc.dashed_arrow(495, 154, 520, 154, label="<<include>>", color=include_color)
    doc.dashed_arrow(520, 274, 495, 274, label="<<extend>>", color=extend_color)
    doc.dashed_arrow(420, 184, 420, 440, label="<<extend>>", color=extend_color)
    doc.dashed_arrow(420, 244, 420, 312, label="<<extend>>", color=extend_color)
    doc.dashed_arrow(420, 214, 420, 154, label="<<extend>>", color=extend_color)
    doc.dashed_arrow(420, 124, 420, 154, label="<<extend>>", color=extend_color)
    doc.dashed_arrow(420, 94, 420, 154, label="<<extend>>", color=extend_color)
    doc.dashed_arrow(420, 64, 420, 154, label="<<extend>>", color=extend_color)

    doc.c.setStrokeColor(include_color)
    doc.c.setDash(4, 3)
    doc.c.line(42, 55, 82, 55)
    doc.c.setDash()
    doc.text(87, 52, "<<include>> = proses wajib/dipakai", size=6.3, color=include_color)
    doc.c.setStrokeColor(extend_color)
    doc.c.setDash(4, 3)
    doc.c.line(42, 42, 82, 42)
    doc.c.setDash()
    doc.text(87, 39, "<<extend>> = fitur opsional/kondisional", size=6.3, color=extend_color)

    doc.text(1.3 * cm, 1.15 * cm, "Catatan: fitur berwarna kuning adalah benefit Premium. Aktor Premium tidak dipisah karena Premium adalah status akun pengguna.", size=7.5, color=GRAY)
    doc.finish_page()


def use_case_description_page(doc: PdfDoc):
    doc.new_page(A4, "2.1 Deskripsi Use Case")
    rows = [
        ["Use Case", "Deskripsi"],
        ["Registrasi/Login", "Pengguna membuat akun atau masuk memakai Firebase Auth; profil awal disimpan di Firestore."],
        ["Jelajah Cafe", "Sistem menampilkan cafe populer, top pick, hidden gems, dan cafe terdekat berdasarkan lokasi."],
        ["Cari dan Filter Cafe", "Pengguna mencari cafe berdasarkan keyword, kota, harga, suasana, kategori, dan sponsor aktif tampil lebih dulu."],
        ["Detail Cafe", "Pengguna melihat foto, alamat, rating, fasilitas, kategori, dan review terverifikasi."],
        ["Wishlist", "Pengguna menyimpan cafe favorit; akun non-premium dibatasi 3 cafe, premium unlimited."],
        ["Tulis Ulasan", "Review harus memiliki rating dan minimal 3 kalimat; foto opsional diunggah ke ImgBB; user mendapat poin."],
        ["Premium", "Pengguna menukar poin untuk premium 7 atau 30 hari dan sistem mencatat riwayat poin."],
        ["Top Up", "Pengguna memilih paket dan metode bayar; backend membuat transaksi Midtrans dan mengembalikan redirect URL."],
        ["Referral", "Pengguna membagikan kode referral; ketika dipakai saat registrasi, kedua pihak mendapat bonus poin."],
        ["Sponsor", "Mitra cafe menghubungi email Kopiku Mana; admin mengaktifkan badge dan prioritas sponsor di data cafe."],
    ]
    doc.table(1.35 * cm, doc.height - 2.35 * cm, [4.3 * cm, doc.width - 7.0 * cm], rows, row_h=42, font_size=7.7)
    doc.finish_page()


def dfd_level_0_page(doc: PdfDoc):
    doc.new_page(landscape(A4), "3. DFD Level 0")
    w, h = doc.width, doc.height
    doc.ellipse(w / 2 - 112, h / 2 - 55, 224, 110, "0. Sistem Kopiku Mana", fill=colors.HexColor("#C7DEF5"), stroke=DARK, size=10)

    entities = {
        "Pengguna": (42, 392, 132, 48, "login, pencarian, review, top up"),
        "Admin Kopiku Mana": (42, 205, 132, 48, "data cafe dan sponsor"),
        "Mitra Cafe": (42, 100, 132, 48, "pengajuan sponsor"),
        "Firebase Auth": (680, 430, 132, 42, "status autentikasi"),
        "Cloud Firestore": (680, 354, 132, 52, "user, cafe, review, poin, referral"),
        "GPS / Geolocator": (680, 278, 132, 42, "koordinat lokasi"),
        "ImgBB": (680, 202, 132, 42, "URL foto"),
        "Backend Railway / Midtrans": (680, 112, 132, 52, "transaksi pembayaran"),
        "SharedPreferences": (42, 310, 132, 42, "notifikasi lokal"),
    }
    for title, (x, y, bw, bh, body) in entities.items():
        doc.box(x, y, bw, bh, title, body, fill=colors.HexColor("#F8F8D8"), stroke=GRAY, radius=2, title_size=7.8)

    cx1, cy = w / 2 - 110, h / 2
    cx2 = w / 2 + 110
    for title in ["Pengguna", "Admin Kopiku Mana", "Mitra Cafe", "SharedPreferences"]:
        x, y, bw, bh, _ = entities[title]
        doc.arrow(x + bw, y + bh / 2, cx1, cy + (y + bh / 2 - cy) * 0.24, label="input/permintaan", color=GRAY)
        doc.arrow(cx1, cy + (y + bh / 2 - cy) * 0.24 - 13, x + bw, y + bh / 2 - 13, label="hasil/info", color=GRAY)

    for title in ["Firebase Auth", "Cloud Firestore", "GPS / Geolocator", "ImgBB", "Backend Railway / Midtrans"]:
        x, y, bw, bh, _ = entities[title]
        label = "query/update" if title == "Cloud Firestore" else "request"
        doc.arrow(cx2, cy + (y + bh / 2 - cy) * 0.23, x, y + bh / 2, label=label, color=BLUE)
        doc.arrow(x, y + bh / 2 - 13, cx2, cy + (y + bh / 2 - cy) * 0.23 - 13, label="response", color=BLUE)

    doc.text(1.25 * cm, 1.15 * cm, "Level 0 menampilkan sistem sebagai satu proses besar dengan aliran data dari/ke pengguna, admin, mitra, dan layanan eksternal.", size=8, color=GRAY)
    doc.finish_page()


def dfd_level_1_page(doc: PdfDoc):
    doc.new_page(landscape(A4), "4. DFD Level 1")
    doc.box(28, 418, 92, 30, "Pengguna", fill=colors.HexColor("#F8F8D8"), stroke=GRAY, radius=1)
    doc.box(28, 334, 92, 30, "Pengguna", fill=colors.HexColor("#F8F8D8"), stroke=GRAY, radius=1)
    doc.box(28, 250, 92, 30, "Pengguna", fill=colors.HexColor("#F8F8D8"), stroke=GRAY, radius=1)
    doc.box(28, 166, 92, 30, "Mitra Cafe", fill=colors.HexColor("#F8F8D8"), stroke=GRAY, radius=1)

    processes = [
        ("P1 Autentikasi", 185, 433, "Login/Register"),
        ("P2 Manajemen Cafe", 185, 349, "Cari & Detail"),
        ("P3 Review & Wishlist", 185, 265, "Review/Wishlist"),
        ("P4 Sponsor", 185, 181, "Ajukan sponsor"),
        ("P5 Poin & Premium", 185, 97, "Referral/Premium"),
        ("P6 Top Up Poin", 410, 181, "Pembayaran"),
        ("P7 Notifikasi Lokal", 635, 349, "Reminder lokal"),
    ]
    for title, x, y, body in processes:
        doc.process_circle(x, y, 31, title, body)

    services = [
        ("Firebase Auth", 690, 418, "Autentikasi."),
        ("GPS / Geolocator", 690, 285, "Koordinat."),
        ("ImgBB", 690, 218, "URL foto."),
        ("Backend Railway/Midtrans", 690, 148, "Pembayaran."),
        ("SharedPreferences", 690, 82, "Notif lokal."),
    ]
    for title, x, y, body in services:
        doc.box(x, y, 125, 40, title, body, fill=colors.HexColor("#EAF4EA"), stroke=GREEN, radius=1, title_size=7.4)

    stores = [
        ("D1 users", 340, 422, "Profil, premium, poin, wishlist."),
        ("D2 cafes", 340, 338, "Cafe, lokasi, rating, sponsor."),
        ("D3 reviews", 340, 254, "Rating, teks, foto."),
        ("D4 point_history", 340, 170, "Riwayat poin dan redeem."),
        ("D5 referral_history", 340, 86, "Riwayat referral."),
    ]
    for title, x, y, body in stores:
        doc.datastore(x, y, 124, 36, title, body)

    # Input dari entitas luar.
    doc.arrow(120, 433, 154, 433, "email/password")
    doc.arrow(120, 349, 154, 349, "keyword/filter")
    doc.arrow(120, 265, 154, 265, "ulasan/wishlist")
    doc.arrow(120, 181, 154, 181, "data sponsor")
    doc.arrow(120, 265, 154, 97, "poin/referral")

    # Proses ke data store.
    doc.arrow(216, 433, 340, 440, "profil user", color=GREEN)
    doc.arrow(216, 349, 340, 356, "baca cafe", color=GREEN)
    doc.arrow(216, 265, 340, 272, "simpan review", color=GREEN)
    doc.arrow(216, 181, 340, 356, "status sponsor", color=GREEN)
    doc.arrow(216, 97, 340, 188, "riwayat poin", color=GREEN)
    doc.arrow(216, 97, 340, 104, "riwayat referral", color=GREEN)
    doc.arrow(410, 212, 464, 188, "top up/redeem", color=GREEN)

    # Data store kembali ke proses.
    doc.arrow(340, 432, 216, 425, "data user", color=colors.HexColor("#E5892F"))
    doc.arrow(340, 348, 216, 341, "data cafe", color=colors.HexColor("#E5892F"))
    doc.arrow(340, 264, 216, 257, "data review", color=colors.HexColor("#E5892F"))
    doc.arrow(464, 180, 379, 181, "status transaksi", color=colors.HexColor("#E5892F"))

    # Layanan eksternal dan proses tambahan.
    doc.arrow(216, 433, 690, 438, "autentikasi", color=BLUE)
    doc.arrow(216, 349, 690, 305, "ambil lokasi", color=BLUE)
    doc.arrow(216, 265, 690, 238, "upload foto", color=BLUE)
    doc.arrow(379, 181, 690, 168, "buat transaksi", color=BLUE)
    doc.arrow(216, 349, 604, 349, "preferensi/notif", color=GRAY)
    doc.arrow(666, 349, 690, 102, "simpan notif", color=GRAY)

    doc.text(1.25 * cm, 1.12 * cm, "Keterangan: lingkaran biru = proses, kotak hijau = sistem eksternal, kotak data = data store, panah hijau/oranye = simpan/baca data.", size=7.5, color=GRAY)
    doc.finish_page()


def dfd_process_table_page(doc: PdfDoc):
    doc.new_page(A4, "4.1 Tabel Proses DFD Level 1")
    rows = [
        ["No", "Proses", "Input", "Output/Data Store"],
        ["1.0", "Autentikasi & Profil", "Email, password, nama, foto, kode referral", "Session, profil - D1 Users, Firebase Auth"],
        ["2.0", "Discovery & Pencarian", "Keyword, filter, koordinat GPS", "Daftar cafe - D2 Cafes"],
        ["3.0", "Detail & Ulasan", "Cafe ID, rating, teks, foto", "Detail, review, poin - D2, D3, D4"],
        ["4.0", "Wishlist", "Cafe ID, status premium", "Wishlist baru/status limit - D1, D2"],
        ["5.0", "Poin & Premium", "Saldo poin, pilihan paket", "Premium aktif, riwayat redeem - D1, D4"],
        ["6.0", "Referral", "Kode referral dan kode user", "Bonus poin, riwayat referral - D1, D4, D5"],
        ["7.0", "Top Up Poin", "Paket, harga, metode bayar, user ID", "Order ID, redirect URL, status transaksi"],
        ["8.0", "Notifikasi Lokal", "Timestamp kunjungan dan status baca", "Daftar notifikasi - SharedPreferences"],
        ["9.0", "Sponsor", "Pengajuan mitra dan status sponsor", "Badge sponsor, prioritas cari - D2 Cafes"],
    ]
    doc.table(1.15 * cm, doc.height - 2.25 * cm, [1.2 * cm, 4.2 * cm, 5.1 * cm, 7.4 * cm], rows, row_h=36, font_size=7.2)
    y = 3.55 * cm
    doc.text(1.35 * cm, y, "Inti Alur Sistem", size=11, bold=True, color=BROWN)
    y -= 16
    doc.bullet_list(
        1.35 * cm,
        y,
        [
            "Splash mengecek session Firebase Auth; pengguna diarahkan ke halaman utama atau login.",
            "Beranda dan eksplorasi membaca data cafe dari Firestore, lalu menampilkan rekomendasi dan hasil filter.",
            "Review divalidasi, foto opsional diunggah ke ImgBB, lalu review dan poin dicatat.",
            "Premium memakai saldo poin; top up memakai backend Railway dan Midtrans.",
            "Sponsor diproses melalui kontak email dan statusnya muncul pada data cafe.",
        ],
        doc.width - 2.7 * cm,
        size=8.5,
    )
    doc.finish_page()


def data_store_page(doc: PdfDoc):
    doc.new_page(A4, "5. Data Store dan Kesimpulan")
    rows = [
        ["Kode", "Data Store", "Isi Data"],
        ["D1", "Users", "UID, nama, email, foto, premium, total poin, kode referral, wishlist, preferensi."],
        ["D2", "Cafes", "Nama cafe, kota, alamat, foto, rating, fasilitas, kategori, harga, lokasi, sponsor."],
        ["D3", "Reviews", "Cafe ID, user ID, rating, teks, foto, status verifikasi, poin, tanggal."],
        ["D4", "Point History", "User ID, jenis transaksi poin, jumlah, deskripsi, tanggal."],
        ["D5", "Referral History", "Referrer, referee, kode referral, poin bonus, tanggal."],
        ["D6", "Top Up Transactions", "User ID, paket, harga, metode bayar, order ID, status pembayaran."],
        ["D7", "SharedPreferences", "Timestamp kunjungan, reminder ulasan, status baca notifikasi."],
    ]
    y = doc.table(1.35 * cm, doc.height - 2.35 * cm, [1.5 * cm, 4.3 * cm, doc.width - 8.5 * cm], rows, row_h=34, font_size=7.6)
    y -= 24
    doc.text(1.35 * cm, y, "Kesimpulan", size=12, bold=True, color=BROWN)
    y -= 16
    doc.para(
        1.35 * cm,
        y,
        "Alur sistem Kopiku Mana berpusat pada pencarian dan rekomendasi cafe. Pengguna masuk ke aplikasi, menemukan cafe melalui rekomendasi atau pencarian, melihat detail, menyimpan wishlist, dan berkontribusi melalui ulasan. Sistem poin menghubungkan aktivitas pengguna, referral, top up, dan premium. Firebase menjadi penyimpanan utama, sedangkan layanan eksternal dipakai untuk lokasi, gambar, pembayaran, dan notifikasi lokal.",
        doc.width - 2.7 * cm,
        size=9.5,
        leading=13,
    )
    doc.finish_page()


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = PdfDoc(OUTPUT)
    title_page(doc)
    overview_page(doc)
    use_case_diagram_page(doc)
    use_case_description_page(doc)
    dfd_level_0_page(doc)
    dfd_level_1_page(doc)
    dfd_process_table_page(doc)
    data_store_page(doc)
    doc.save()
    print(f"Generated {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
