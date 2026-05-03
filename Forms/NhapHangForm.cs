using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

namespace CongCafe
{
    public partial class NhapHangForm : Form
    {
        TextBox txtMaNV, txtMaNCC, txtThueVAT, txtMaHD;
        ComboBox cbThanhToan;
        TextBox txtMaNVL, txtSoLuong, txtDonGia;
        DateTimePicker dtpHSD;
        DataGridView dgv;
        Label lblTongTien;

        public NhapHangForm()
        {
            Text = "Nhập Hàng";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            // TĂNG CHIỀU CAO PANEL LÊN 130 ĐỂ RỘNG RÃI HƠN
            Panel pnlHD = new Panel() { Height = 130, Dock = DockStyle.Top, BorderStyle = BorderStyle.FixedSingle };

            // Dòng 1 (Y = 20)
            pnlHD.Controls.Add(new Label() { Text = "Mã NV:", Location = new Point(20, 20), AutoSize = true });
            txtMaNV = new TextBox() { Location = new Point(100, 20), Width = 120 };

            pnlHD.Controls.Add(new Label() { Text = "Mã NCC:", Location = new Point(240, 20), AutoSize = true });
            txtMaNCC = new TextBox() { Location = new Point(320, 20), Width = 120 };

            pnlHD.Controls.Add(new Label() { Text = "Thuế VAT:", Location = new Point(460, 20), AutoSize = true });
            txtThueVAT = new TextBox() { Location = new Point(540, 20), Width = 80, Text = "0.1" };

            Button btnTaoHD = new Button() { Text = "Tạo HĐ", Location = new Point(650, 18), Width = 100 };
            btnTaoHD.Click += BtnTaoHD_Click;

            Button btnXoaHD = new Button() { Text = "Xóa toàn bộ HĐ", Location = new Point(770, 18), Width = 140 };
            btnXoaHD.Click += BtnXoaHD_Click;

            // Dòng 2 (Y = 70) -> Cách dòng trên 50px
            pnlHD.Controls.Add(new Label() { Text = "PT TToán:", Location = new Point(20, 70), AutoSize = true });
            cbThanhToan = new ComboBox() { Location = new Point(100, 70), Width = 200 };
            cbThanhToan.Items.AddRange(new[] { "Tiền mặt", "Chuyển khoản" });
            cbThanhToan.SelectedIndex = 0;

            // Đưa ô text Mã HD xuống dòng 2, thẳng hàng với nút Tạo HĐ
            txtMaHD = new TextBox() { Location = new Point(650, 70), Width = 260, ReadOnly = true };

            pnlHD.Controls.AddRange(new Control[] { txtMaNV, txtMaNCC, txtThueVAT, cbThanhToan, btnTaoHD, txtMaHD, btnXoaHD });

            // PANEL CHI TIẾT
            Panel pnlCT = new Panel() { Height = 80, Dock = DockStyle.Top };

            // Dòng 1 của Panel Chi Tiết (Y = 25)
            pnlCT.Controls.Add(new Label() { Text = "Mã NVL:", Location = new Point(20, 25), AutoSize = true });
            txtMaNVL = new TextBox() { Location = new Point(100, 25), Width = 100 };

            pnlCT.Controls.Add(new Label() { Text = "Số lượng:", Location = new Point(220, 25), AutoSize = true });
            txtSoLuong = new TextBox() { Location = new Point(300, 25), Width = 80 };

            pnlCT.Controls.Add(new Label() { Text = "Đơn giá:", Location = new Point(400, 25), AutoSize = true });
            txtDonGia = new TextBox() { Location = new Point(480, 25), Width = 120 };

            pnlCT.Controls.Add(new Label() { Text = "HSD:", Location = new Point(620, 25), AutoSize = true });
            dtpHSD = new DateTimePicker() { Location = new Point(670, 25), Format = DateTimePickerFormat.Short, Width = 130 };

            Button btnThemCT = new Button() { Text = "Thêm Dòng", Location = new Point(820, 23), Width = 100 };
            btnThemCT.Click += BtnThemCT_Click;

            Button btnXoaCT = new Button() { Text = "Xóa Dòng", Location = new Point(930, 23), Width = 100 };
            btnXoaCT.Click += BtnXoaCT_Click;

            pnlCT.Controls.AddRange(new Control[] { txtMaNVL, txtSoLuong, txtDonGia, dtpHSD, btnThemCT, btnXoaCT });

            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true, SelectionMode = DataGridViewSelectionMode.FullRowSelect };
            lblTongTien = new Label() { Text = "Tổng Tiền HĐ: 0", Dock = DockStyle.Bottom, Font = new Font("Segoe UI", 14, FontStyle.Bold), Height = 50, TextAlign = ContentAlignment.MiddleRight };

            Controls.Add(dgv);
            Controls.Add(lblTongTien);
            Controls.Add(pnlCT);
            Controls.Add(pnlHD);
        }

        private void BtnTaoHD_Click(object sender, EventArgs e)
        {
            var inputs = new[] {
                new SqlParameter("@MaNV", txtMaNV.Text),
                new SqlParameter("@MaNCC", txtMaNCC.Text),
                new SqlParameter("@NgayLap", DateTime.Now),
                new SqlParameter("@PTThanhToan", cbThanhToan.Text),
                new SqlParameter("@ThueVAT", Convert.ToDecimal(txtThueVAT.Text))
            };
            var res = DatabaseHelper.ExecuteProc("sp_ThemHoaDonNhap", inputs, new[] { "@MaHD_NH_Out" });
            MessageBox.Show(res.ThongBao);
            if (res.Check)
            {
                txtMaHD.Text = res.Outputs["@MaHD_NH_Out"].ToString();
                LoadChiTiet();
            }
        }

        private void BtnThemCT_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMaHD.Text)) { MessageBox.Show("Vui lòng tạo hóa đơn trước!"); return; }
            var inputs = new[] {
                new SqlParameter("@MaHD_NH", txtMaHD.Text),
                new SqlParameter("@MaNVL", txtMaNVL.Text),
                new SqlParameter("@SoLuong", Convert.ToInt32(txtSoLuong.Text)),
                new SqlParameter("@DonGiaNVL", Convert.ToDecimal(txtDonGia.Text)),
                new SqlParameter("@HSD", dtpHSD.Value)
            };
            var res = DatabaseHelper.ExecuteProc("sp_ThemCTHD_Nhap", inputs);
            if (!res.Check) MessageBox.Show(res.ThongBao);
            LoadChiTiet();
        }

        private void BtnXoaCT_Click(object sender, EventArgs e)
        {
            if (dgv.SelectedRows.Count == 0 || string.IsNullOrEmpty(txtMaHD.Text)) return;
            string maNVL = dgv.SelectedRows[0].Cells["MaNVL"].Value.ToString();
            var res = DatabaseHelper.ExecuteProc("sp_XoaChiTietHoaDonNhap", new[] {
                new SqlParameter("@MaHD_NH", txtMaHD.Text), new SqlParameter("@MaNVL", maNVL)
            });
            MessageBox.Show(res.ThongBao);
            LoadChiTiet();
        }

        private void BtnXoaHD_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMaHD.Text)) return;
            var res = DatabaseHelper.ExecuteProc("sp_XoaHoaDonNhap", new[] { new SqlParameter("@MaHD_NH", txtMaHD.Text) });
            MessageBox.Show(res.ThongBao);
            if (res.Check) { txtMaHD.Clear(); dgv.DataSource = null; lblTongTien.Text = "Tổng Tiền HĐ: 0"; }
        }

        private void LoadChiTiet()
        {
            if (string.IsNullOrEmpty(txtMaHD.Text)) return;
            dgv.DataSource = DatabaseHelper.GetData($"SELECT * FROM CTHD_NHAP WHERE MaHD_NH = '{txtMaHD.Text}'");
            DataTable dtHD = DatabaseHelper.GetData($"SELECT TongTien FROM HOADON_NHAP WHERE MaHD_NH = '{txtMaHD.Text}'");
            if (dtHD.Rows.Count > 0) lblTongTien.Text = $"Tổng Tiền HĐ: {dtHD.Rows[0]["TongTien"]:#,##0} VNĐ";
        }
    }
}
