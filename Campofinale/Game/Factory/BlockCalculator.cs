using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Campofinale.Resource.ResourceManager;

namespace Campofinale.Game.Factory
{
    public class BlockCalculator
    {
        public static int CalculateTotalBlocks(List<Vector3f> points)
        {
            if (points == null || points.Count < 2)
                return 0;

            HashSet<Tuple<int, int, int>> blocks = new HashSet<Tuple<int, int, int>>();

            for (int i = 0; i < points.Count - 1; i++)
            {
                Vector3f p1 = points[i];
                Vector3f p2 = points[i + 1];

                AddBlocksForLineSegment3D(p1, p2, blocks);
            }

            return blocks.Count;
        }

        private static void AddBlocksForLineSegment3D(Vector3f p1, Vector3f p2, HashSet<Tuple<int, int, int>> blocks)
        {
            int x0 = (int)Math.Floor(p1.x);
            int y0 = (int)Math.Floor(p1.y);
            int z0 = (int)Math.Floor(p1.z);
            int x1 = (int)Math.Floor(p2.x);
            int y1 = (int)Math.Floor(p2.y);
            int z1 = (int)Math.Floor(p2.z);

            int dx = Math.Abs(x1 - x0);
            int dy = Math.Abs(y1 - y0);
            int dz = Math.Abs(z1 - z0);
            int sx = x0 < x1 ? 1 : -1;
            int sy = y0 < y1 ? 1 : -1;
            int sz = z0 < z1 ? 1 : -1;

            if (dx >= dy && dx >= dz)
            {
                int err1 = 2 * dy - dx;
                int err2 = 2 * dz - dx;
                for (int i = 0; i < dx; i++)
                {
                    blocks.Add(Tuple.Create(x0, y0, z0));
                    if (err1 > 0)
                    {
                        y0 += sy;
                        err1 -= 2 * dx;
                    }
                    if (err2 > 0)
                    {
                        z0 += sz;
                        err2 -= 2 * dx;
                    }
                    err1 += 2 * dy;
                    err2 += 2 * dz;
                    x0 += sx;
                }
            }
            else if (dy >= dx && dy >= dz)
            {
                int err1 = 2 * dx - dy;
                int err2 = 2 * dz - dy;
                for (int i = 0; i < dy; i++)
                {
                    blocks.Add(Tuple.Create(x0, y0, z0));
                    if (err1 > 0)
                    {
                        x0 += sx;
                        err1 -= 2 * dy;
                    }
                    if (err2 > 0)
                    {
                        z0 += sz;
                        err2 -= 2 * dy;
                    }
                    err1 += 2 * dx;
                    err2 += 2 * dz;
                    y0 += sy;
                }
            }
            else
            {
                int err1 = 2 * dy - dz;
                int err2 = 2 * dx - dz;
                for (int i = 0; i < dz; i++)
                {
                    blocks.Add(Tuple.Create(x0, y0, z0));
                    if (err1 > 0)
                    {
                        y0 += sy;
                        err1 -= 2 * dz;
                    }
                    if (err2 > 0)
                    {
                        x0 += sx;
                        err2 -= 2 * dz;
                    }
                    err1 += 2 * dy;
                    err2 += 2 * dx;
                    z0 += sz;
                }
            }

            blocks.Add(Tuple.Create(x1, y1, z1));
        }
    }
}
