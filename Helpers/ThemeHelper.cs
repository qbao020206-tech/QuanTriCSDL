using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace CongCafe
{
    public static class ThemeHelper
    {
        // ===== COLOR PALETTE: CongCafe Branding =====
        public static Color CongGreen = Color.FromArgb(75, 83, 32);        // Xanh lính (Header, Active)
        public static Color CongBeige = Color.FromArgb(238, 232, 213);     // Vàng bao cấp (Background)
        public static Color CongBrown = Color.FromArgb(78, 52, 46);        // Nâu gỗ (Text)
        public static Color CongRed = Color.FromArgb(178, 34, 34);         // Đỏ (Delete, Error)
        public static Color CongHighlight = Color.FromArgb(107, 112, 92);  // Xanh nhạt (Hover)

        // Modern flat design: Lighter variants for accessibility
        public static Color CongGreenLight = Color.FromArgb(120, 140, 70);
        public static Color CongBrownDark = Color.FromArgb(50, 30, 20);

        /// <summary>
        /// Apply modern flat design theme to all controls in a form
        /// </summary>
        public static void ApplyTheme(Control control)
        {
            if (control is Form frm)
            {
                frm.BackColor = CongBeige;
                frm.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
            }

            foreach (Control c in control.Controls)
            {
                StyleControl(c);
                if (c.HasChildren)
                {
                    ApplyTheme(c);
                }
            }
        }

        /// <summary>
        /// Style individual control with flat design
        /// </summary>
        private static void StyleControl(Control c)
        {
            if (c is Panel pnl)
            {
                pnl.BackColor = CongBeige;
            }
            else if (c is Label lbl)
            {
                lbl.ForeColor = CongBrown;
                lbl.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
                lbl.AutoSize = true;
            }
            else if (c is Button btn)
            {
                StyleButton(btn);
            }
            else if (c is TextBox txt)
            {
                StyleTextBox(txt);
            }
            else if (c is ComboBox cb)
            {
                StyleComboBox(cb);
            }
            else if (c is DateTimePicker dtp)
            {
                StyleDateTimePicker(dtp);
            }
            else if (c is DataGridView dgv)
            {
                StyleDataGridView(dgv);
            }
            else if (c is CheckBox chk)
            {
                chk.Font = new Font("Segoe UI", 10F);
                chk.ForeColor = CongBrown;
                chk.BackColor = CongBeige;
            }
        }

        private static void StyleButton(Button btn)
        {
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 0;
            btn.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
            btn.ForeColor = Color.White;
            btn.Cursor = Cursors.Hand;

            // Determine button color based on text
            if (btn.Text.ToLower().Contains("xóa") || btn.Text.ToLower().Contains("hủy") || btn.Text.ToLower().Contains("đăng xuất"))
            {
                btn.BackColor = CongRed;
                btn.FlatAppearance.MouseOverBackColor = Color.FromArgb(200, 50, 50);
            }
            else
            {
                btn.BackColor = CongGreen;
                btn.FlatAppearance.MouseOverBackColor = CongHighlight;
            }
        }

        private static void StyleTextBox(TextBox txt)
        {
            txt.BorderStyle = BorderStyle.FixedSingle;
            txt.BackColor = Color.White;
            txt.ForeColor = CongBrown;
            txt.Font = new Font("Segoe UI", 11F, FontStyle.Regular);
            txt.MinimumSize = new Size(0, 28);

            // Add subtle border styling
            txt.Padding = new Padding(5, 5, 5, 5);
        }

        private static void StyleComboBox(ComboBox cb)
        {
            cb.Font = new Font("Segoe UI", 11F, FontStyle.Regular);
            cb.ForeColor = CongBrown;
            cb.BackColor = Color.White;
            cb.FlatStyle = FlatStyle.Flat;
            cb.MinimumSize = new Size(0, 28);
        }

        private static void StyleDateTimePicker(DateTimePicker dtp)
        {
            dtp.Font = new Font("Segoe UI", 11F, FontStyle.Regular);
            dtp.ForeColor = CongBrown;
            dtp.CalendarForeColor = CongBrown;
            dtp.CalendarMonthBackground = Color.White;
        }

        private static void StyleDataGridView(DataGridView dgv)
        {
            // ===== SIZE & LAYOUT =====
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgv.RowTemplate.Height = 35;
            dgv.RowHeadersVisible = false;
            dgv.AllowUserToAddRows = false;

            // ===== COLORS & STYLING =====
            dgv.EnableHeadersVisualStyles = false;
            dgv.BorderStyle = BorderStyle.None;
            dgv.BackgroundColor = CongBeige;
            dgv.GridColor = Color.FromArgb(200, 200, 190);

            // Header styling
            dgv.ColumnHeadersDefaultCellStyle.BackColor = CongGreen;
            dgv.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
            dgv.ColumnHeadersDefaultCellStyle.Font = new Font("Segoe UI", 11F, FontStyle.Bold);
            dgv.ColumnHeadersDefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleCenter;
            dgv.ColumnHeadersHeight = 40;

            // Row styling
            dgv.DefaultCellStyle.BackColor = Color.White;
            dgv.DefaultCellStyle.ForeColor = CongBrown;
            dgv.DefaultCellStyle.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
            dgv.DefaultCellStyle.SelectionBackColor = CongHighlight;
            dgv.DefaultCellStyle.SelectionForeColor = Color.White;
            dgv.DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleLeft;
            dgv.DefaultCellStyle.Padding = new Padding(5);

            // Alternating row colors (striped pattern)
            dgv.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(248, 248, 245);
            dgv.AlternatingRowsDefaultCellStyle.ForeColor = CongBrown;

            // Read-only cells styling
            dgv.DefaultCellStyle.BackColor = Color.White;
        }

        /// <summary>
        /// Apply modern rounded button styling
        /// </summary>
        public static void ApplyModernButtonStyle(Button btn, bool isPrimary = true)
        {
            btn.FlatStyle = FlatStyle.Flat;
            btn.FlatAppearance.BorderSize = 0;
            btn.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
            btn.Cursor = Cursors.Hand;
            btn.MinimumSize = new Size(100, 35);

            if (isPrimary)
            {
                btn.BackColor = CongGreen;
                btn.ForeColor = Color.White;
                btn.FlatAppearance.MouseOverBackColor = CongHighlight;
            }
            else
            {
                btn.BackColor = Color.LightGray;
                btn.ForeColor = CongBrown;
                btn.FlatAppearance.MouseOverBackColor = Color.FromArgb(220, 220, 210);
            }
        }

        /// <summary>
        /// Create a gradient background for a panel
        /// </summary>
        public static void ApplyGradientBackground(Panel panel, Color colorStart, Color colorEnd)
        {
            panel.Paint += (s, e) =>
            {
                LinearGradientBrush brush = new LinearGradientBrush(
                    new Point(0, 0),
                    new Point(0, panel.Height),
                    colorStart, colorEnd);
                e.Graphics.FillRectangle(brush, panel.ClientRectangle);
                brush.Dispose();
            };
        }

        /// <summary>
        /// Responsive sizing: Scale control based on screen DPI
        /// </summary>
        public static void ApplyResponsiveLayout(Control control)
        {
            float dpiScale = control.CreateGraphics().DpiX / 96f;

            foreach (Control c in GetAllControls(control))
            {
                c.Width = (int)(c.Width * dpiScale);
                c.Height = (int)(c.Height * dpiScale);
                c.Left = (int)(c.Left * dpiScale);
                c.Top = (int)(c.Top * dpiScale);
                c.Font = new Font(c.Font.FontFamily, c.Font.Size * dpiScale);
            }
        }

        /// <summary>
        /// Get all controls recursively
        /// </summary>
        private static System.Collections.Generic.List<Control> GetAllControls(Control parent)
        {
            var controls = new System.Collections.Generic.List<Control>();
            foreach (Control c in parent.Controls)
            {
                controls.Add(c);
                controls.AddRange(GetAllControls(c));
            }
            return controls;
        }
    }
}