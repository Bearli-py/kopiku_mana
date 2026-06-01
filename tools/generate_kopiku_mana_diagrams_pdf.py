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
    boundary = (155, 64, 535, 430)
    doc.c.setFillColor(colors.white)
    doc.c.setStrokeColor(BROWN)
    doc.c.roundRect(*boundary, 10, fill=1, stroke=1)
    doc.text(boundary[0] + boundary[2] / 2, boundary[1] + boundary[3] - 20, "Sistem Kopiku Mana", size=13, bold=True, color=BROWN, align="center")

    actors = {
        "Pengguna": (70, 325),
        "Pengguna Baru": (70, 213),
        "Mitra Cafe": (70, 105),
        "Firebase": (760, 405),
        "GPS": (760, 335),
        "ImgBB": (760, 265),
        "Backend/Midtrans": (760, 195),
        "Admin": (760, 105),
    }
    for label, (x, y) in actors.items():
        doc.actor(x, y, label)

    groups = [
        ("Akun", 190, 392, ["Registrasi", "Login", "Reset Password", "Kelola Profil"]),
        ("Cari Cafe", 420, 392, ["Jelajah Cafe", "Cari & Filter", "Lihat Detail"]),
        ("Aktivitas Pengguna", 190, 245, ["Wishlist", "Tulis Ulasan", "Lihat Riwayat", "Atur Notifikasi"]),
        ("Poin & Membership", 420, 245, ["Referral", "Top Up Poin", "Aktifkan Premium"]),
        ("Sponsor & Admin", 305, 110, ["Ajukan Sponsor", "Kelola Data Cafe"]),
    ]
    group_centers = {}
    for title, x, y, items in groups:
        doc.box(x, y - 112, 190, 112, title, fill=CREAM, stroke=BROWN, radius=9, title_size=9.5)
        group_centers[title] = (x + 95, y - 56)
        item_y = y - 37
        for item in items:
            doc.ellipse(x + 24, item_y - 16, 142, 25, item, fill=colors.white, stroke=colors.HexColor("#B58B71"), size=7.2)
            item_y -= 23

    def actor_to_group(actor, group, label):
        ax, ay = actors[actor]
        gx, gy = group_centers[group]
        doc.arrow(ax + 24, ay + 16, gx - 95, gy, label=label, color=GRAY)

    actor_to_group("Pengguna", "Akun", "masuk/profil")
    actor_to_group("Pengguna", "Cari Cafe", "mencari")
    actor_to_group("Pengguna", "Aktivitas Pengguna", "menyimpan/review")
    actor_to_group("Pengguna", "Poin & Membership", "poin")
    actor_to_group("Pengguna Baru", "Akun", "daftar")
    actor_to_group("Mitra Cafe", "Sponsor & Admin", "sponsor")

    def service_to_group(service, group, label, color=BLUE):
        sx, sy = actors[service]
        gx, gy = group_centers[group]
        doc.arrow(sx - 24, sy + 16, gx + 95, gy, label=label, color=color)

    service_to_group("Firebase", "Akun", "auth")
    service_to_group("GPS", "Cari Cafe", "lokasi", color=GREEN)
    service_to_group("ImgBB", "Aktivitas Pengguna", "foto")
    service_to_group("Backend/Midtrans", "Poin & Membership", "bayar")
    service_to_group("Admin", "Sponsor & Admin", "kelola")

    doc.text(1.3 * cm, 1.15 * cm, "Cara baca: kiri adalah aktor utama, tengah adalah kelompok fitur, kanan adalah layanan/admin yang membantu proses.", size=8, color=GRAY)
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
    doc.box(w / 2 - 110, h / 2 - 55, 220, 110, "0. Sistem Kopiku Mana", "Flutter mobile app untuk rekomendasi cafe, review, wishlist, poin, premium, referral, dan top up.", fill=LIGHT_BROWN, stroke=BROWN, radius=14, title_size=11)

    entities = {
        "Pengguna": (42, 375, 120, 64, "Kredensial, pencarian, wishlist, review, premium, top up"),
        "Admin Kopiku Mana": (42, 185, 120, 64, "Data cafe, sponsor, kurasi top pick/hidden gems"),
        "Mitra Cafe": (42, 82, 120, 64, "Pengajuan sponsor via email"),
        "Firebase Auth": (690, 420, 120, 50, "Login, register, reset password"),
        "Cloud Firestore": (690, 340, 120, 58, "Users, cafes, reviews, poin, referral, transaksi"),
        "Geolocator/GPS": (690, 265, 120, 50, "Koordinat lokasi"),
        "ImgBB": (690, 190, 120, 50, "Upload foto dan URL gambar"),
        "Railway/Midtrans": (690, 105, 120, 58, "Order ID, redirect pembayaran, status transaksi"),
    }
    for title, (x, y, bw, bh, body) in entities.items():
        doc.box(x, y, bw, bh, title, body, fill=colors.white, stroke=BLUE if x > w / 2 else BROWN, radius=5, title_size=8.4)

    cx1, cy = w / 2 - 110, h / 2
    cx2 = w / 2 + 110
    for title in ["Pengguna", "Admin Kopiku Mana", "Mitra Cafe"]:
        x, y, bw, bh, _ = entities[title]
        doc.arrow(x + bw, y + bh / 2, cx1, cy + (y + bh / 2 - cy) * 0.24, label="input/permintaan", color=GRAY)
        doc.arrow(cx1, cy + (y + bh / 2 - cy) * 0.24 - 13, x + bw, y + bh / 2 - 13, label="hasil/info", color=GRAY)

    for title in ["Firebase Auth", "Cloud Firestore", "Geolocator/GPS", "ImgBB", "Railway/Midtrans"]:
        x, y, bw, bh, _ = entities[title]
        label = "query/update" if title == "Cloud Firestore" else "request"
        doc.arrow(cx2, cy + (y + bh / 2 - cy) * 0.23, x, y + bh / 2, label=label, color=BLUE)
        doc.arrow(x, y + bh / 2 - 13, cx2, cy + (y + bh / 2 - cy) * 0.23 - 13, label="response", color=BLUE)

    doc.text(1.25 * cm, 1.15 * cm, "Level 0 menampilkan sistem sebagai satu proses besar dengan aliran data dari/ke pengguna, admin, mitra, dan layanan eksternal.", size=8, color=GRAY)
    doc.finish_page()


def dfd_level_1_page(doc: PdfDoc):
    doc.new_page(landscape(A4), "4. DFD Level 1")
    doc.box(30, 372, 105, 56, "Pengguna", "Login, cari cafe, wishlist, review, poin, premium, top up.", fill=colors.white, stroke=BROWN, radius=5)
    doc.box(30, 260, 105, 50, "Mitra Cafe", "Mengajukan sponsor via email.", fill=colors.white, stroke=BROWN, radius=5)
    doc.box(30, 150, 105, 50, "Admin", "Mengelola cafe dan sponsor.", fill=colors.white, stroke=BROWN, radius=5)

    processes = [
        ("1.0 Autentikasi", 170, 392, "Validasi login/register dan profil."),
        ("2.0 Cari Cafe", 330, 392, "Ambil cafe, filter, hitung jarak."),
        ("3.0 Detail Cafe", 490, 392, "Tampilkan detail dan ulasan."),
        ("4.0 Wishlist & Review", 170, 255, "Simpan cafe dan kirim ulasan."),
        ("5.0 Poin, Referral, Premium", 330, 255, "Tambah/kurangi poin dan aktifkan premium."),
        ("6.0 Top Up & Notifikasi", 490, 255, "Buat transaksi dan notifikasi lokal."),
        ("7.0 Sponsor", 650, 255, "Prioritas cafe sponsor di hasil cari."),
    ]
    for title, x, y, body in processes:
        doc.box(x, y, 125, 62, title, body, fill=LIGHT_BROWN, stroke=BROWN, radius=10, title_size=8.2)

    services = [
        ("Firebase Auth", 650, 408, "Autentikasi akun."),
        ("GPS", 650, 340, "Koordinat lokasi."),
        ("ImgBB", 650, 186, "Foto review/profil."),
        ("Backend/Midtrans", 650, 118, "Pembayaran top up."),
    ]
    for title, x, y, body in services:
        doc.box(x, y, 125, 44, title, body, fill=colors.white, stroke=BLUE if title != "GPS" else GREEN, radius=4, title_size=8)

    stores = [
        ("D1 Users", 170, 68, "Profil, poin, premium, wishlist, referral."),
        ("D2 Cafes", 302, 68, "Data cafe, lokasi, rating, sponsor."),
        ("D3 Reviews", 434, 68, "Ulasan, rating, foto, verifikasi."),
        ("D4 Point History", 566, 68, "Riwayat poin."),
        ("D5 Referral History", 698, 68, "Riwayat referral."),
    ]
    for title, x, y, body in stores:
        doc.datastore(x, y, 118, 46, title, body)

    # Alur utama dibuat berurutan agar mudah dibaca.
    doc.arrow(135, 400, 170, 423, "akun")
    doc.arrow(295, 423, 330, 423, "session")
    doc.arrow(455, 423, 490, 423, "pilih cafe")
    doc.arrow(232, 392, 232, 317, "profil")
    doc.arrow(392, 392, 392, 317, "hasil cafe")
    doc.arrow(552, 392, 232, 317, "cafe ID")
    doc.arrow(295, 286, 330, 286, "poin review")
    doc.arrow(455, 286, 490, 286, "saldo/status")
    doc.arrow(615, 286, 650, 286, "sponsor")
    doc.arrow(135, 285, 650, 286, "pengajuan")
    doc.arrow(135, 175, 650, 286, "kelola data")

    # Layanan eksternal.
    doc.arrow(295, 423, 650, 430, "auth", color=BLUE)
    doc.arrow(455, 423, 650, 362, "lokasi", color=GREEN)
    doc.arrow(295, 286, 650, 208, "foto", color=BLUE)
    doc.arrow(552, 255, 650, 140, "transaksi", color=BLUE)

    # Data store utama, hanya garis penting.
    doc.arrow(232, 255, 229, 114, "D1")
    doc.arrow(392, 392, 361, 114, "D2")
    doc.arrow(552, 392, 493, 114, "D3")
    doc.arrow(392, 255, 625, 114, "D4")
    doc.arrow(392, 255, 757, 114, "D5")
    doc.arrow(712, 255, 361, 114, "D2 sponsor", color=BLUE)

    doc.text(1.25 * cm, 1.12 * cm, "Cara baca: alur utama dari kiri ke kanan; bagian bawah adalah data store yang dipakai proses.", size=8, color=GRAY)
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
