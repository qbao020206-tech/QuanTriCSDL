using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace CongCafe
{
    /// <summary>
    /// UIHelper: Utilities cho flat design modern - vẽ rounded shapes, gradients, etc.
    /// </summary>
    public static class UIHelper
    {
        // ===== GRADIENT & BACKGROUND =====
        
        /// <summary>
        /// Vẽ gradient background từ trên xuống dưới
        /// </summary>
        public static void DrawGradientBackground(Graphics g, Rectangle rect, Color colorStart, Color colorEnd)
        {
            using (LinearGradientBrush brush = new LinearGradientBrush(
                new Point(rect.Left, rect.Top),
                new Point(rect.Left, rect.Bottom),
                colorStart, colorEnd))
            {
                g.FillRectangle(brush, rect);
            }
        }

        /// <summary>
        /// Vẽ gradient từ trái sang phải
        /// </summary>
        public static void DrawGradientBackgroundHorizontal(Graphics g, Rectangle rect, Color colorStart, Color colorEnd)
        {
            using (LinearGradientBrush brush = new LinearGradientBrush(
                new Point(rect.Left, rect.Top),
                new Point(rect.Right, rect.Top),
                colorStart, colorEnd))
            {
                g.FillRectangle(brush, rect);
            }
        }

        // ===== ROUNDED RECTANGLES =====

        /// <summary>
        /// Vẽ rounded rectangle (border + fill)
        /// </summary>
        public static void DrawRoundedRectangle(Graphics g, Rectangle rect, int radius, Color borderColor, Color fillColor, int borderWidth = 1)
        {
            using (GraphicsPath path = GetRoundedRectanglePath(rect, radius))
            {
                // Vẽ nền
                using (SolidBrush fillBrush = new SolidBrush(fillColor))
                {
                    g.FillPath(fillBrush, path);
                }

                // Vẽ border
                using (Pen pen = new Pen(borderColor, borderWidth))
                {
                    g.DrawPath(pen, path);
                }
            }
        }

        /// <summary>
        /// Vẽ rounded rectangle (chỉ fill, không border)
        /// </summary>
        public static void DrawRoundedRectangleFill(Graphics g, Rectangle rect, int radius, Color fillColor)
        {
            using (GraphicsPath path = GetRoundedRectanglePath(rect, radius))
            {
                using (SolidBrush brush = new SolidBrush(fillColor))
                {
                    g.FillPath(brush, path);
                }
            }
        }

        /// <summary>
        /// Vẽ rounded rectangle với gradient fill
        /// </summary>
        public static void DrawRoundedRectangleGradient(Graphics g, Rectangle rect, int radius, 
            Color colorStart, Color colorEnd, LinearGradientMode mode)
        {
            using (GraphicsPath path = GetRoundedRectanglePath(rect, radius))
            {
                using (LinearGradientBrush brush = new LinearGradientBrush(rect, colorStart, colorEnd, mode))
                {
                    g.FillPath(brush, path);
                }
            }
        }

        /// <summary>
        /// Vẽ rounded rectangle (chỉ border)
        /// </summary>
        public static void DrawRoundedRectangleBorder(Graphics g, Rectangle rect, int radius, Color borderColor, int borderWidth = 1)
        {
            using (GraphicsPath path = GetRoundedRectanglePath(rect, radius))
            {
                using (Pen pen = new Pen(borderColor, borderWidth))
                {
                    pen.LineJoin = LineJoin.Round;
                    g.DrawPath(pen, path);
                }
            }
        }

        /// <summary>
        /// Get GraphicsPath cho rounded rectangle
        /// </summary>
        public static GraphicsPath GetRoundedRectanglePath(Rectangle rect, int radius)
        {
            GraphicsPath path = new GraphicsPath();
            int diameter = radius * 2;

            // Giảm kích thước để tránh vẽ quá viền
            rect.Width--;
            rect.Height--;

            // Các góc
            path.AddArc(rect.X, rect.Y, diameter, diameter, 180, 90);
            path.AddArc(rect.X + rect.Width - diameter, rect.Y, diameter, diameter, 270, 90);
            path.AddArc(rect.X + rect.Width - diameter, rect.Y + rect.Height - diameter, diameter, diameter, 0, 90);
            path.AddArc(rect.X, rect.Y + rect.Height - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();

            return path;
        }

        // ===== SHADOW EFFECTS =====

        /// <summary>
        /// Vẽ shadow (Dark overlay phía dưới/phải)
        /// </summary>
        public static void DrawShadow(Graphics g, Rectangle rect, int shadowSize, Color shadowColor)
        {
            // Vẽ shadow phía dưới
            using (SolidBrush shadowBrush = new SolidBrush(shadowColor))
            {
                g.FillRectangle(shadowBrush, new Rectangle(
                    rect.X + shadowSize,
                    rect.Y + shadowSize,
                    rect.Width,
                    rect.Height));
            }
        }

        // ===== ICON HELPERS =====

        /// <summary>
        /// Vẽ icon mắt (xem/ẩn password)
        /// </summary>
        public static void DrawEyeIcon(Graphics g, Rectangle rect, bool isOpen, Color color)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using (Pen pen = new Pen(color, 2))
            {
                int centerX = rect.X + rect.Width / 2;
                int centerY = rect.Y + rect.Height / 2;
                int eyeRadius = 8;
                int pupilRadius = 4;

                if (isOpen)
                {
                    // Vẽ mắt mở
                    g.DrawEllipse(pen, centerX - eyeRadius, centerY - eyeRadius / 2, eyeRadius * 2, eyeRadius);
                    g.FillEllipse(new SolidBrush(color), centerX - pupilRadius, centerY - pupilRadius / 2, pupilRadius * 2, pupilRadius);
                }
                else
                {
                    // Vẽ mắt đóng (gạch ngang)
                    g.DrawLine(pen, centerX - eyeRadius, centerY, centerX + eyeRadius, centerY);
                }
            }
        }

        /// <summary>
        /// Vẽ icon người dùng (circle với U bên trong)
        /// </summary>
        public static void DrawUserIcon(Graphics g, Rectangle rect, Color color)
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            using (Pen pen = new Pen(color, 2))
            using (SolidBrush brush = new SolidBrush(color))
            {
                int radius = Math.Min(rect.Width, rect.Height) / 2;
                int centerX = rect.X + rect.Width / 2;
                int centerY = rect.Y + rect.Height / 2;

                // Vẽ đầu (circle)
                g.FillEllipse(brush, centerX - radius / 3, centerY - radius / 2, radius * 2 / 3, radius * 2 / 3);

                // Vẽ thân (arc)
                g.DrawArc(pen, centerX - radius, centerY, radius * 2, radius, 0, 180);
            }
        }

        // ===== TEXT RENDERING =====

        /// <summary>
        /// Vẽ text centered trong rectangle
        /// </summary>
        public static void DrawCenteredText(Graphics g, string text, Font font, Color color, Rectangle rect)
        {
            StringFormat format = new StringFormat
            {
                Alignment = StringAlignment.Center,
                LineAlignment = StringAlignment.Center
            };

            using (SolidBrush brush = new SolidBrush(color))
            {
                g.DrawString(text, font, brush, rect, format);
            }
        }

        // ===== ANIMATION HELPERS =====

        /// <summary>
        /// Tính toán alpha (opacity) value dựa trên animation progress (0.0 - 1.0)
        /// </summary>
        public static int GetAlphaForProgress(float progress)
        {
            return Math.Max(0, Math.Min(255, (int)(progress * 255)));
        }

        /// <summary>
        /// Easing function: ease-in-out (smooth start & end)
        /// </summary>
        public static float EaseInOutQuad(float progress)
        {
            if (progress < 0.5f)
                return 2 * progress * progress;
            else
                return -1 + (4 - 2 * progress) * progress;
        }

        /// <summary>
        /// Easing function: ease-out (smooth end)
        /// </summary>
        public static float EaseOutQuad(float progress)
        {
            return 1 - (1 - progress) * (1 - progress);
        }
    }
}
