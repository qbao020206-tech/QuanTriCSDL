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
    public partial class NCCForm : Form
    {
        DataGridView dgv;
        TextBox txtMaNCC, txtTenNCC, txtDiaChi, txtSDT;
        private int currentPage = 1;
        private int pageSize = 10;
        private Label lblPageInfo;

        public NCCForm()
        {
            Text = "Quản Lý Nhà Cung Cấp";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();
            LoadData();

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            Panel pnlTop = new Panel() { Height = 180, Dock = DockStyle.Top };

            pnlTop.Controls.Add(new Label() { Text = "Mã NCC:", Location = new Point(20, 20), AutoSize = true });
            txtMaNCC = new TextBox() { Location = new Point(100, 20), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Tên NCC:", Location = new Point(280, 20), AutoSize = true });
            txtTenNCC = new TextBox() { Location = new Point(360, 20), Width = 220 };

            Button btnThem = new Button() { Text = "Thêm", Location = new Point(620, 18), Width = 100 };
            btnThem.Click += BtnThem_Click;

            pnlTop.Controls.Add(new Label() { Text = "SĐT:", Location = new Point(20, 70), AutoSize = true });
            txtSDT = new TextBox() { Location = new Point(100, 70), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Địa Chỉ:", Location = new Point(280, 70), AutoSize = true });
            txtDiaChi = new TextBox() { Location = new Point(360, 70), Width = 220 };

            Button btnSua = new Button() { Text = "Sửa", Location = new Point(620, 68), Width = 100 };
            btnSua.Click += BtnSua_Click;

            Button btnXoa = new Button() { Text = "Xóa", Location = new Point(740, 68), Width = 100 };
            btnXoa.Click += BtnXoa_Click;

            Button btnPrev = new Button() { Text = "< Trước", Location = new Point(20, 130), Width = 80 };
            btnPrev.Click += (s, e) => { if (currentPage > 1) { currentPage--; LoadData(); } };

            Button btnNext = new Button() { Text = "Tiếp >", Location = new Point(110, 130), Width = 80 };
            btnNext.Click += (s, e) => { currentPage++; LoadData(); };

            lblPageInfo = new Label() { Location = new Point(200, 135), AutoSize = true, Text = "Trang 1" };

            pnlTop.Controls.AddRange(new Control[] { txtMaNCC, txtTenNCC, txtDiaChi, txtSDT, btnThem, btnSua, btnXoa, btnPrev, btnNext, lblPageInfo });

            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true, SelectionMode = DataGridViewSelectionMode.FullRowSelect };
            dgv.CellClick += (s, e) => {
                if (e.RowIndex >= 0)
                {
                    DataGridViewRow r = dgv.Rows[e.RowIndex];
                    txtMaNCC.Text = r.Cells["MaNCC"].Value.ToString();
                    txtTenNCC.Text = r.Cells["TenNCC"].Value.ToString();
                    txtDiaChi.Text = r.Cells["DiaChiNCC"].Value.ToString();
                    txtSDT.Text = r.Cells["SDTNCC"].Value.ToString();
                }
            };

            Controls.Add(dgv);
            Controls.Add(pnlTop);
        }

        private void LoadData()
        {
            string query = $"SELECT * FROM NCC ORDER BY MaNCC OFFSET {(currentPage - 1) * pageSize} ROWS FETCH NEXT {pageSize} ROWS ONLY";
            dgv.DataSource = DatabaseHelper.GetData(query);
            int totalRecords = PaginationHelper.GetTotalRecords("NCC");
            int totalPages = (int)Math.Ceiling((double)totalRecords / pageSize);
            lblPageInfo.Text = $"Trang {currentPage}/{totalPages} ({totalRecords} nhà cung cấp)";
            if (currentPage >= totalPages) currentPage = totalPages;
        }

        private void BtnThem_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_ThemNCC", new[] {
                new SqlParameter("@MaNCC", txtMaNCC.Text),
                new SqlParameter("@TenNCC", txtTenNCC.Text),
                new SqlParameter("@DiaChiNCC", txtDiaChi.Text),
                new SqlParameter("@SDTNCC", txtSDT.Text)
            });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnSua_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_SuaNCC", new[] {
                new SqlParameter("@MaNCC", txtMaNCC.Text),
                new SqlParameter("@TenNCC", txtTenNCC.Text),
                new SqlParameter("@DiaChiNCC", txtDiaChi.Text),
                new SqlParameter("@SDTNCC", txtSDT.Text)
            });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnXoa_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_XoaNCC", new[] { new SqlParameter("@MaNCC", txtMaNCC.Text) });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }
    }
}
