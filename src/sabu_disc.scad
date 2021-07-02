use <conic_section.scad>
use <mirror_copy.scad>
use <array.scad>
use <pipe.scad>
use <wormhole.scad>

/*
*   Sabu disc module
*/
module sabu_disc(fins, fin_h, fin_d, fin_t, hole_r, hole_arc_deg, hole_margin, plate_r, plate_c, plate_t, pole_r, pole_t, pole_h, pole_fi, pole_fo, rim_edge, rim_open_deg)
{
    module open_ellipse(a, b, deg_open)
    {
        semi_open = deg_open/2;
        rx = cos(semi_open);
        ry = sin(semi_open);

        scale([a, b])
            difference()
            {
                circle(1);
                polygon([
                    [0, 0],
                    [rx, ry],
                    [1, ry],
                    [1, -ry],
                    [rx, -ry]
                ]);
            }
    }

    /*
    *   NOTE: Looks wrong for high eccentricity and low opening angle
    */
    module open_elliptical_pipe(a, b, thickness, deg_open, edge = 0, half = false)
    {
        edge_a = edge;
        edge_b = thickness/2;

        semi_open = deg_open/2;
        rx = cos(semi_open);
        ry = sin(semi_open);

        difference()
        {
            open_ellipse(a + edge_b, b + edge_b, deg_open);
            scale([1, (b - edge_b)/(a - edge_b)])
                circle(a - edge_b);

            if (half)
            {
                translate([-(a + thickness), -(b + thickness)])
                    square([2*a + thickness, b + thickness]);
            }
        }

        if (edge_a > 0)
        {
            if (half)
            {
                intersection()
                {
                    scale([1, b/a])
                    translate([a*cos(deg_open/2), a*sin(deg_open/2)])
                    rotate([0, 0, deg_open/2 - 90])
                    scale([1, (a/b)*edge_b/edge_a])
                        circle(edge_a);

                    scale([2*(a + edge_b), 2*(b + edge_b)])
                        polygon([
                            [0, 0],
                            [rx, ry],
                            [1, ry],
                            [1, 0]
                        ]);
                }
            }
            else
            {
                intersection()
                {
                    mirror_copy([0, 1, 0])
                    scale([1, b/a])
                    translate([a*cos(deg_open/2), a*sin(deg_open/2)])
                    rotate([0, 0, deg_open/2 - 90])
                    scale([1, (a/b)*edge_b/edge_a])
                        circle(edge_a);

                    scale([2*(a + edge_b), 2*(b + edge_b)])
                        polygon([
                            [0, 0],
                            [rx, ry],
                            [1, ry],
                            [1, -ry],
                            [rx, -ry]
                        ]);
                }
            }
        }
    }

    /*
    *   Rim submodule
    */
    module rim(radius, wall_a, wall_b, wall_thickness, wall_edge, deg_open, half=false)
    {
        wall_edge_a = wall_edge;
        wall_edge_b = wall_thickness*0.5;
        wall_a_in = wall_a - wall_edge_b;
        wall_a_out = wall_a + wall_edge_b;

        tan_semi_open = tan(deg_open/2);

        rotate_extrude()
        translate([radius, 0, 0])
        mirror([1, 0, 0])
            open_elliptical_pipe(
                a=wall_a,
                b=wall_b,
                thickness=wall_thickness,
                deg_open=deg_open,
                edge=wall_edge*2,
                half=true
            );
    }

    /*
    *   Fin submodule
    */
    module fin(w, h, a, b, thickness, deg)
    {
        a_out = a + thickness/2;
        b_out = b + thickness/2;

        ri = (w/2)/sin(deg/2);
        rix = ri*cos(deg/2);
        r = ri + a_out;

        x_offset = h + rix;

        translate([-rix, 0, 0])
            intersection()
            {
                rotate([0, 0, -deg/2])
                    wormhole(r, a, b, thickness, deg);

                translate([x_offset, 0, -b_out])
                mirror([1, 0, 0])
                linear_extrude(2*b_out)
                resize([h, w])
                    children(0);
            }
    }

    /*
    *   Holes submodule
    */
    module hole(w, h, a, b, thickness, deg)
    {
        a_out = a + thickness/2;
        b_out = b + thickness/2;

        ri = (w/2)/sin(deg/2);
        rix = ri*cos(deg/2);
        r = ri + a_out;

        translate([-rix, 0, 0])
            intersection()
            {
                rotate([0, 0, -deg/2])
                rotate_extrude(angle=deg)
                translate([r, 0, -b_out])
                scale([a_out, b_out])
                    difference()
                    {
                        translate([-1, -1])
                            square(1);
                        circle(1);
                    }
            }
    }

    /*
    *   Plate submodule
    */
    module plate(holes, a, b, thickness, hole_r, hole_arc_deg, hole_margin)
    {
        difference()
        {
            rotate_extrude()
                intersection()
                {
                    difference()
                    {
                        scale([a + thickness/2, b + thickness/2])
                            circle(1);
                        scale([a - thickness/2, b - thickness/2])
                            circle(1);
                    }
                    translate([0, -(b + thickness/2)])
                        square([a + thickness/2, b + thickness/2]);
                }

            hole_tan_r = a - hole_margin;
            opposite = hole_r*sin(hole_arc_deg/2);
            adjacent = hole_r*cos(hole_arc_deg/2);
            radius = sqrt(hole_tan_r*hole_tan_r - opposite*opposite) + adjacent;

            intersection()
            {
                polar_array(
                    count=holes,
                    radius=radius,
                    start_angle=0,
                    end_angle=360
                )
                    cylinder(r=hole_r, h=3*b, center=true);

                cylinder(r=a - hole_margin, h=2*(b + thickness/2), center=true);
            }
        }
    }

    /*
    *   Pole submodule
    */
    module pole(ri, ro, h, fi, fo)
    {
        pipe(
            ri=ri,
            ro=ro,
            h=h,
            center=false
        );

        rotate_extrude()
        translate([ro + fo, fo, 0])
        rotate([180, 180, 0])
            difference()
            {
                square(fo);
                circle(fo);
            }

        rotate_extrude()
        translate([ri - fi, fi, 0])
        rotate([180, 0, 0])
            difference()
            {
                square(fi);
                circle(fi);
            }
    }

    /*
    *   Create Rim around the circumference of the Plate
    */
    rim(
        radius=plate_r - plate_t,
        wall_a=plate_t,
        wall_b=plate_t,
        wall_thickness=plate_t,
        wall_edge=rim_edge,
        deg_open=rim_open_deg,
        half=true
    );

    plate_m_r = plate_r - hole_margin;

    fin_a = hole_r*(1 - cos(hole_arc_deg/2)) + fin_h;
    fin_w = 2*hole_r*sin(hole_arc_deg/2);
    fin_array_r = sqrt(plate_m_r*plate_m_r - (fin_w/2)*(fin_w/2));
    fin_z = -(plate_c*sqrt(1 - (plate_m_r/plate_r)*(plate_m_r/plate_r)));

    /*
    *   Create Fins
    */
    difference()
    {
        polar_array(
            count=fins,
            radius=fin_array_r,
            start_angle=0,
            end_angle=360
        )
            translate([0, 0, fin_z])
            mirror([1, 0, 0])
                fin(
                    w=fin_w,
                    h=fin_h,
                    a=fin_a,
                    b=fin_d,
                    thickness=fin_t,
                    deg=hole_arc_deg
                )
                    conic_section(
                        cone_h=10,
                        cone_angle=70,
                        plane_angle=85,
                        plane_offset=1,
                        mirror_cone=false,
                        normalize_origin=true
                    );

        difference()
        {
            translate([0, 0, -(plate_c + fin_d)])
                cube([2*plate_r + plate_t, 2*plate_r + plate_t, 2*(plate_c + fin_d)], center=true);
            scale([plate_r + plate_t/2, plate_r + plate_t/2, plate_c + plate_t/2])
                sphere(1);
        }
    }

    /*
    *   Create Plate
    */
    difference()
    {
        plate(
            holes=fins,
            a=plate_r,
            b=plate_c,
            thickness=plate_t,
            hole_r=hole_r,
            hole_arc_deg=hole_arc_deg,
            hole_margin=hole_margin
        );

        /*
        *   Create Holes in the plate
        */
        polar_array(
            count=fins,
            radius=fin_array_r + 0.01,
            start_angle=0,
            end_angle=360
        )
            translate([0, 0, fin_z])
            mirror([1, 0, 0])
                hole(
                    w=fin_w,
                    h=fin_h,
                    a=fin_a,
                    b=fin_d,
                    thickness=fin_t,
                    deg=hole_arc_deg
                );
    }

    /*
    *   Create Pole
    */
    translate([0, 0, -(plate_c - plate_t/2)])
        pole(
            ri=pole_r - pole_t/2,
            ro=pole_r + pole_t/2,
            h=pole_h,
            fi=pole_fi,
            fo=pole_fo
        );
}

/*
*   Preview/Test model
*/
$fa = 3;
$fs = 0.05;

rotate([0, 0, 360*$t])
    sabu_disc(
        fins=3,
        fin_h=11,
        fin_d=4,
        fin_t=0.5,

        hole_r=15,
        hole_arc_deg=90,
        hole_margin=1,

        plate_r=20,
        plate_c=2,
        plate_t=0.5,

        pole_r=3,
        pole_t=0.5,
        pole_h=4,
        pole_fi=0.75,
        pole_fo=0.5,

        rim_edge=0.5,
        rim_open_deg=160
    );