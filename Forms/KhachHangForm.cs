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
    public partial class KhachHangForm : Form
    {
        DataGridView dgv;
        TextBox txtMa, txtTen, txtSDT, txtDiaChi;
        DateTimePicker dtpNgaySinh;
        private int currentPage = 1;
        private int pageSize = 10;
        private Label lblPageInfo;

        public KhachHangForm()
        {
            Text = "Quản Lý Khách Hàng";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();

            try
            {
                LoadData();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            Panel pnlTop = new Panel() { Height = 200, Dock = DockStyle.Top };

            pnlTop.Controls.Add(new Label() { Text = "Mã KH:", Location = new Point(20, 20), AutoSize = true });
            txtMa = new TextBox() { Location = new Point(100, 20), Width = 150, ReadOnly = true };

            pnlTop.Controls.Add(new Label() { Text = "Ngày Sinh:", Location = new Point(280, 20), AutoSize = true });
            dtpNgaySinh = new DateTimePicker() { Location = new Point(370, 20), Format = DateTimePickerFormat.Short, Width = 150 };

            Button btnThem = new Button() { Text = "Thêm", Location = new Point(560, 18), Width = 100 };
            btnThem.Click += BtnThem_Click;

            pnlTop.Controls.Add(new Label() { Text = "Tên KH:", Location = new Point(20, 70), AutoSize = true });
            txtTen = new TextBox() { Location = new Point(100, 70), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "SĐT:", Location = new Point(280, 70), AutoSize = true });
            txtSDT = new TextBox() { Location = new Point(370, 70), Width = 150 };

            Button btnSua = new Button() { Text = "Sửa", Location = new Point(560, 68), Width = 100 };
            btnSua.Click += BtnSua_Click;

            pnlTop.Controls.Add(new Label() { Text = "Địa Chỉ:", Location = new Point(20, 120), AutoSize = true });
            txtDiaChi = new TextBox() { Location = new Point(100, 120), Width = 420 };

            Button btnXoa = new Button() { Text = "Xóa", Location = new Point(560, 118), Width = 100, Enabled = GlobalState.IsManager };
            btnXoa.Click += BtnXoa_Click;

            Button btnPrev = new Button() { Text = "< Trước", Location = new Point(20, 160), Width = 80 };
            btnPrev.Click += (s, e) => { if (currentPage > 1) { currentPage--; LoadData(); } };

            Button btnNext = new Button() { Text = "Tiếp >", Location = new Point(110, 160), Width = 80 };
            btnNext.Click += (s, e) => { currentPage++; LoadData(); };

            lblPageInfo = new Label() { Location = new Point(200, 165), AutoSize = true, Text = "Trang 1" };

            pnlTop.Controls.AddRange(new Control[] { txtMa, txtTen, dtpNgaySinh, txtSDT, txtDiaChi, btnThem, btnSua, btnXoa, btnPrev, btnNext, lblPageInfo });

            dgv = new DataGridView()
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            };

            dgv.DataError += (s, e) => { e.ThrowException = false; };

            dgv.CellClick += (s, e) => {
                if (e.RowIndex >= 0)
                {
                    DataGridViewRow r = dgv.Rows[e.RowIndex];
                    txtMa.Text = r.Cells["MaKH"].Value?.ToString();
                    txtTen.Text = r.Cells["TenKH"].Value?.ToString();
                    if (r.Cells["NgaySinhKH"].Value != DBNull.Value)
                        dtpNgaySinh.Value = Convert.ToDateTime(r.Cells["NgaySinhKH"].Value);
                    txtDiaChi.Text = r.Cells["DiaChiKH"].Value?.ToString();
                    txtSDT.Text = r.Cells["SDTKH"].Value?.ToString();
                }
            };

            Controls.Add(dgv);
            Controls.Add(pnlTop);
        }

        private void LoadData()
        {
            string query = $"SELECT MaKH, TenKH, NgaySinhKH, DiaChiKH, SDTKH FROM KHACHHANG ORDER BY MaKH DESC OFFSET {(currentPage - 1) * pageSize} ROWS FETCH NEXT {pageSize} ROWS ONLY";
            dgv.DataSource = DatabaseHelper.GetData(query);
            int totalRecords = PaginationHelper.GetTotalRecords("KHACHHANG");
            int totalPages = (int)Math.Ceiling((double)totalRecords / pageSize);
            lblPageInfo.Text = $"Trang {currentPage}/{totalPages} ({totalRecords} khách hàng)";
            if (currentPage >= totalPages) currentPage = totalPages;
        }

        private void BtnThem_Click(object sender, EventArgs e)
        {
            var inputs = new[] {
                new SqlParameter("@TenKH", txtTen.Text),
                new SqlParameter("@NgaySinhKH", dtpNgaySinh.Value),
                new SqlParameter("@DiaChiKH", txtDiaChi.Text),
                new SqlParameter("@SDTKH", txtSDT.Text)
            };
            var res = DatabaseHelper.ExecuteProc("sp_ThemKhachHang", inputs);
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnSua_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMa.Text)) return;
            var inputs = new[] {
                new SqlParameter("@MaKH", txtMa.Text),
                new SqlParameter("@TenKH", txtTen.Text),
                new SqlParameter("@NgaySinhKH", dtpNgaySinh.Value),
                new SqlParameter("@DiaChiKH", txtDiaChi.Text),
                new SqlParameter("@SDTKH", txtSDT.Text)
            };
            var res = DatabaseHelper.ExecuteProc("sp_SuaKhachHang", inputs);
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnXoa_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtMa.Text)) return;
            if (MessageBox.Show("Bạn có chắc muốn xóa khách hàng này?", "Xác nhận", MessageBoxButtons.YesNo) == DialogResult.Yes)
            {
                var res = DatabaseHelper.ExecuteProc("sp_XoaKhachHang", new[] { new SqlParameter("@MaKH", txtMa.Text) });
                MessageBox.Show(res.ThongBao);
                if (res.Check) { txtMa.Clear(); LoadData(); }
            }
        }
    }
}