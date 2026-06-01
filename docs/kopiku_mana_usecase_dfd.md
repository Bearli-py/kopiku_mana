# Use Case Diagram dan DFD Kopiku Mana

Dokumen ini merangkum rancangan use case diagram, DFD level 0, dan DFD level 1 untuk aplikasi Kopiku Mana. Isi disusun berdasarkan alur yang ada pada aplikasi Flutter saat ini.

## 1. Gambaran Sistem

Kopiku Mana adalah aplikasi rekomendasi cafe wilayah Tapal Kuda. Pengguna dapat login, mencari cafe, melihat detail cafe, menyimpan wishlist, menulis ulasan, mengumpulkan poin, memakai referral, melakukan top up poin, dan menukar poin untuk akses premium.

### Aktor dan Sistem Eksternal

| Aktor/Sistem | Peran |
| --- | --- |
| Pengguna | Mengakses aplikasi, mencari cafe, melihat detail, membuat wishlist, menulis ulasan, mengelola profil, referral, premium, dan top up. |
| Pengguna Baru | Melakukan registrasi dan dapat memasukkan kode referral. |
| Admin Kopiku Mana | Mengelola data cafe, status sponsor, dan data pendukung melalui Firebase/operasional luar aplikasi. |
| Mitra Cafe | Mengajukan kerja sama sponsor melalui email yang tersedia di aplikasi. |
| Firebase Auth | Memproses login, registrasi, reset password, dan sesi pengguna. |
| Cloud Firestore | Menyimpan data user, cafe, review, wishlist, poin, referral, dan transaksi. |
| Geolocator/GPS | Memberikan lokasi pengguna untuk rekomendasi cafe terdekat. |
| ImgBB | Menyimpan foto profil dan foto ulasan. |
| Backend Railway/Midtrans | Membuat transaksi top up dan menghubungkan pembayaran dengan Midtrans. |
| SharedPreferences | Menyimpan data notifikasi lokal seperti kunjungan terakhir dan status baca. |

## 2. Use Case Diagram

### Daftar Use Case

| Use Case | Aktor Utama | Deskripsi |
| --- | --- | --- |
| Registrasi Akun | Pengguna Baru | Pengguna membuat akun baru, sistem menyimpan profil awal dan kode referral. |
| Login | Pengguna | Pengguna masuk ke aplikasi memakai email dan password. |
| Reset Password | Pengguna | Pengguna meminta email reset password ketika lupa kata sandi. |
| Jelajah Cafe | Pengguna | Pengguna melihat cafe populer, top pick, hidden gems, dan cafe terdekat. |
| Cari dan Filter Cafe | Pengguna | Pengguna mencari cafe berdasarkan nama, kota, kecamatan, suasana, kategori, harga, dan filter lain. |
| Lihat Detail Cafe | Pengguna | Pengguna melihat foto, alamat, rating, fasilitas, kategori, dan ulasan cafe. |
| Kelola Wishlist | Pengguna | Pengguna menyimpan atau menghapus cafe favorit. Akun non-premium dibatasi 3 cafe. |
| Tulis Ulasan | Pengguna | Pengguna memberi rating, menulis minimal 3 kalimat, menambahkan foto opsional, lalu mendapatkan poin. |
| Kelola Profil | Pengguna | Pengguna melihat dan memperbarui data profil termasuk foto. |
| Aktifkan Premium | Pengguna | Pengguna menukar poin untuk premium 7 hari atau 30 hari. |
| Top Up Poin | Pengguna | Pengguna memilih paket poin dan metode pembayaran, lalu sistem membuat transaksi pembayaran. |
| Bagikan Referral | Pengguna | Pengguna menyalin atau membagikan kode referral untuk mendapatkan poin. |
| Lihat Riwayat | Pengguna | Pengguna melihat riwayat ulasan, poin, dan referral. |
| Atur Notifikasi | Pengguna | Pengguna melihat dan mengatur notifikasi lokal/rekomendasi. |
| Ajukan Sponsor | Mitra Cafe | Mitra menghubungi Kopiku Mana melalui email untuk kerja sama sponsor. |
| Kelola Data Cafe | Admin Kopiku Mana | Admin mengelola data cafe, kurasi hidden gems/top pick, dan sponsor di database. |

### Relasi Use Case

- "Registrasi Akun" menyertakan validasi referral jika pengguna mengisi kode.
- "Jelajah Cafe" dapat memakai lokasi GPS untuk menampilkan cafe terdekat.
- "Cari dan Filter Cafe" menampilkan cafe sponsor lebih dahulu bila sponsor aktif.
- "Tulis Ulasan" dapat menyertakan upload foto ke ImgBB.
- "Aktifkan Premium" menyertakan validasi saldo poin dan pencatatan riwayat poin.
- "Top Up Poin" menyertakan pembuatan transaksi melalui backend pembayaran.
- "Kelola Wishlist" memperluas benefit premium karena premium membuka wishlist tanpa batas.

## 3. DFD Level 0

DFD level 0 menggambarkan sistem Kopiku Mana sebagai satu proses utama yang berinteraksi dengan entitas luar.

### Entitas Luar

| Entitas | Data Masuk ke Sistem | Data Keluar dari Sistem |
| --- | --- | --- |
| Pengguna | Kredensial, data profil, keyword/filter, permintaan detail, wishlist, ulasan, pilihan premium, referral, top up | Status login, daftar cafe, detail cafe, status wishlist, poin, status premium, riwayat, notifikasi |
| Admin Kopiku Mana | Data cafe, status sponsor, status hidden gems/top pick | Laporan data cafe/review/transaksi melalui database |
| Mitra Cafe | Permintaan kerja sama sponsor via email | Informasi paket dan instruksi kerja sama |
| Firebase Auth | Status autentikasi | Permintaan login, register, reset password |
| Cloud Firestore | Data user, cafe, review, poin, referral, transaksi | Query dan perubahan data aplikasi |
| Geolocator/GPS | Koordinat lokasi pengguna | Permintaan izin/lokasi |
| ImgBB | URL gambar | File foto profil atau ulasan |
| Backend Railway/Midtrans | Order ID, redirect URL, status transaksi | Detail paket, harga, metode bayar, user ID |
| SharedPreferences | Status notifikasi lokal | Timestamp kunjungan dan status baca |

### Penjelasan DFD Level 0

Pengguna berinteraksi dengan aplikasi Kopiku Mana untuk menjalankan seluruh fitur utama. Sistem memproses input tersebut dengan bantuan Firebase Auth untuk autentikasi dan Firestore untuk penyimpanan data. Untuk fitur lokasi, sistem meminta data koordinat dari GPS. Untuk foto profil dan foto ulasan, sistem mengunggah gambar ke ImgBB dan menyimpan URL-nya. Untuk top up poin, sistem mengirim data paket pembayaran ke backend Railway yang terhubung ke Midtrans. Mitra cafe tidak mengelola data langsung di aplikasi, tetapi mengajukan sponsor melalui email. Admin mengelola data cafe dan sponsor melalui proses operasional di database.

## 4. DFD Level 1

DFD level 1 memecah sistem Kopiku Mana menjadi proses utama berikut.

| No | Proses | Input | Output | Data Store |
| --- | --- | --- | --- | --- |
| 1.0 | Autentikasi dan Profil | Email, password, nama, foto profil, kode referral | Session login, profil pengguna, status error/sukses | D1 Users, Firebase Auth |
| 2.0 | Discovery dan Pencarian Cafe | Keyword, filter kota/harga/suasana, koordinat GPS | Daftar cafe populer, terdekat, top pick, hidden gems, hasil pencarian | D2 Cafes |
| 3.0 | Detail Cafe dan Ulasan | Cafe ID, rating, teks ulasan, foto ulasan | Detail cafe, daftar review, review baru, poin review | D2 Cafes, D3 Reviews, D1 Users, D4 Point History |
| 4.0 | Wishlist | Cafe ID, status premium | Wishlist baru, status limit, cafe tersimpan/dihapus | D1 Users, D2 Cafes |
| 5.0 | Poin dan Premium | Pilihan paket premium, saldo poin | Status premium aktif, pengurangan poin, riwayat redeem | D1 Users, D4 Point History |
| 6.0 | Referral | Kode referral, kode milik pengguna | Bonus poin, riwayat referral, pesan share | D1 Users, D4 Point History, D5 Referral History |
| 7.0 | Top Up Poin | Paket poin, harga, metode bayar, user ID | Order ID, redirect URL, status transaksi | D6 Top Up Transactions, Backend/Midtrans |
| 8.0 | Notifikasi Lokal | Waktu kunjungan, status baca, nama pengguna | Daftar notifikasi, status unread/read | D7 SharedPreferences |
| 9.0 | Sponsor dan Kemitraan | Permintaan mitra, data sponsor cafe | Informasi paket, badge sponsor, prioritas pencarian | D2 Cafes |

### Alur Utama DFD Level 1

1. Pengguna membuka aplikasi. Splash screen mengecek sesi Firebase Auth. Jika sudah login, pengguna masuk ke halaman utama; jika belum, pengguna diarahkan ke login/register.
2. Pada registrasi, sistem membuat akun di Firebase Auth, membuat dokumen user di Firestore, membuat kode referral, dan menambahkan bonus poin jika kode referral valid.
3. Halaman utama mengambil data cafe dari Firestore. Jika izin lokasi tersedia, sistem menghitung jarak cafe dari koordinat pengguna untuk section cafe terdekat.
4. Pengguna mencari atau memfilter cafe. Sistem membaca data cafe, mencocokkan keyword/filter, lalu mengurutkan cafe sponsor aktif lebih dulu.
5. Pengguna membuka detail cafe. Sistem menampilkan data cafe dan review terverifikasi.
6. Pengguna menulis ulasan. Sistem memvalidasi rating dan minimal 3 kalimat, mengunggah foto opsional ke ImgBB, menyimpan review, lalu memberi poin review.
7. Pengguna menambah cafe ke wishlist. Sistem mengecek status premium dan jumlah wishlist. Non-premium dibatasi 3 cafe, premium tidak dibatasi.
8. Pengguna mengaktifkan premium dengan poin. Sistem mengecek saldo poin, mengurangi poin, mengatur tanggal kedaluwarsa premium, dan mencatat riwayat.
9. Pengguna melakukan top up poin. Sistem mengirim data paket ke backend Railway, backend membuat transaksi Midtrans, lalu sistem menampilkan order ID dan link pembayaran.
10. Pengguna membagikan referral. Jika kode dipakai saat registrasi pengguna lain, kedua pihak mendapat bonus poin dan riwayat referral dicatat.
11. Sistem membuat notifikasi lokal berdasarkan kunjungan terakhir, reminder review, dan kondisi weekend.
12. Mitra cafe menghubungi email Kopiku Mana untuk sponsor. Setelah diproses admin, cafe dapat muncul dengan badge sponsor dan prioritas di hasil pencarian.

## 5. Data Store

| Kode | Nama Data Store | Isi Data |
| --- | --- | --- |
| D1 | Users | UID, nama, email, foto, status premium, premium expiry, total poin, kode referral, wishlist, preferensi. |
| D2 | Cafes | Nama cafe, kota, kecamatan, alamat, foto, rating, fasilitas, kategori, harga, lokasi, status top pick/hidden gem/sponsor. |
| D3 | Reviews | Cafe ID, user ID, nama pengguna, rating, teks, foto, status verifikasi, poin, tanggal. |
| D4 | Point History | User ID, jenis transaksi poin, jumlah poin, deskripsi, tanggal. |
| D5 | Referral History | Referrer ID, referee ID, kode referral, poin bonus, tanggal. |
| D6 | Top Up Transactions | User ID, paket, harga, metode bayar, order ID, status pembayaran. |
| D7 | SharedPreferences | Timestamp kunjungan terakhir, reminder ulasan terakhir, status baca notifikasi. |

## 6. Kesimpulan

Alur sistem Kopiku Mana berpusat pada pencarian dan rekomendasi cafe. Pengguna masuk ke aplikasi, menemukan cafe melalui rekomendasi atau pencarian, melihat detail, menyimpan wishlist, dan berkontribusi melalui ulasan. Sistem poin menjadi penghubung antara aktivitas pengguna, referral, top up, dan premium. Data utama disimpan di Firebase, sedangkan layanan eksternal dipakai untuk lokasi, gambar, pembayaran, dan notifikasi lokal.
