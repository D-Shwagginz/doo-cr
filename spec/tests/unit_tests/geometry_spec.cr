module Doocr::Test
  describe Geometry, tags: "geometry" do
    it "Point On Side1" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        node = Node.new(
          Fixed.from_f64(start_x),
          Fixed.zero,
          Fixed.from_f64(end_x - start_x),
          Fixed.zero,
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          0, 0
        )

        x = Fixed.from_f64(point_x)

        y = Fixed.from_f64(front_side_y)
        Geometry.point_on_side(x, y, node).should eq 0

        y = Fixed.from_f64(back_side_y)
        Geometry.point_on_side(x, y, node).should eq 1
      end
    end

    it "Point On Side2" do
      random = Random.new(666)
      1000.times do |i|
        start_y = +1 + 666 * random.next_float
        end_y = -1 - 666 * random.next_float

        point_y = 666 * random.next_float - 333
        front_side_x = -1 - 666 * random.next_float
        back_side_x = -front_side_x

        node = Node.new(
          Fixed.zero,
          Fixed.from_f64(start_y),
          Fixed.zero,
          Fixed.from_f64(end_y - start_y),
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          0, 0
        )

        y = Fixed.from_f64(point_y)

        x = Fixed.from_f64(front_side_x)
        Geometry.point_on_side(x, y, node).should eq 0

        x = Fixed.from_f64(back_side_x)
        Geometry.point_on_side(x, y, node).should eq 1
      end
    end

    it "Point On Side3" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        100.times do |j|
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333

          node = Node.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta)),
            Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            Fixed.from_f64((end_x - start_x) * Math.sin(theta)),
            Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
            Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
            0, 0
          )

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta))
          Geometry.point_on_side(x, y, node).should eq 0

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta))
          Geometry.point_on_side(x, y, node).should eq 1
        end
      end
    end

    it "Point To Dist" do
      random = Random.new(666)
      i = 0
      while i < 1000
        expected = i

        100.times do |j|
          r = i
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333
          x = ox + r * Math.cos(theta)
          y = oy + r * Math.sin(theta)
          from_x = Fixed.from_f64(ox)
          from_y = Fixed.from_f64(oy)
          to_x = Fixed.from_f64(x)
          to_y = Fixed.from_f64(y)
          dist = Geometry.point_to_dist(from_x, from_y, to_x, to_y)
          expected.should be_close(dist.to_f64, i.to_f64 / 100)
        end

        i += 3
      end
    end

    it "Point To Angle" do
      random = Random.new(666)
      100.times do |i|
        expected = 2 * Math::PI * random.next_float
        100.times do |j|
          r = 666 * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333
          x = ox + r * Math.cos(expected)
          y = oy + r * Math.sin(expected)
          from_x = Fixed.from_f64(ox)
          from_y = Fixed.from_f64(oy)
          to_x = Fixed.from_f64(x)
          to_y = Fixed.from_f64(y)
          angle = Geometry.point_to_angle(from_x, from_y, to_x, to_y)
          actual = angle.to_radian
          expected.should be_close(actual, 0.46)
        end
      end
    end

    it "Point In Subsector E1M1" do
      content = GameContent.create_dummy(WadPath::DOOM1)
      options = GameOptions.new
      world = World.new(content, options, nil)
      map = Map.new(content, world)

      ok = 0
      count = 0

      map.subsectors.each do |subsector|
        subsector.seg_count.times do |i|
          seg = map.segs[subsector.first_seg + i]

          p1x = seg.vertex1.as(Vertex).x.to_f64
          p1y = seg.vertex1.as(Vertex).y.to_f64
          p2x = seg.vertex2.as(Vertex).x.to_f64
          p2y = seg.vertex2.as(Vertex).y.to_f64

          dx = p2x - p1x
          dy = p2y - p1y
          length = Math.sqrt(dx * dx + dy * dy)

          center_x = (p1x + p2x) / 2
          center_y = (p1y + p2y) / 2
          step_x = dy / length
          step_y = -dx / length

          target_x = center_x + 3 * step_x
          target_y = center_y + 3 * step_y

          fx = Fixed.from_f64(target_x)
          fy = Fixed.from_f64(target_y)

          result = Geometry.point_in_subsector(fx, fy, map)

          ok += 1 if result == subsector
          count += 1
        end
      end

      (ok.to_f64 / count).should be >= 0.995
    end

    it "Point In Subsector Map01" do
      content = GameContent.create_dummy(WadPath::DOOM2)
      options = GameOptions.new
      world = World.new(content, options, nil)
      map = Map.new(content, world)

      ok = 0
      count = 0

      map.subsectors.each do |subsector|
        subsector.seg_count.times do |i|
          seg = map.segs[subsector.first_seg + i]

          p1x = seg.vertex1.as(Vertex).x.to_f64
          p1y = seg.vertex1.as(Vertex).y.to_f64
          p2x = seg.vertex2.as(Vertex).x.to_f64
          p2y = seg.vertex2.as(Vertex).y.to_f64

          dx = p2x - p1x
          dy = p2y - p1y
          length = Math.sqrt(dx * dx + dy * dy)

          center_x = (p1x + p2x) / 2
          center_y = (p1y + p2y) / 2
          step_x = dy / length
          step_y = -dx / length

          target_x = center_x + 3 * step_x
          target_y = center_y + 3 * step_y

          fx = Fixed.from_f64(target_x)
          fy = Fixed.from_f64(target_y)

          result = Geometry.point_in_subsector(fx, fy, map)

          ok += 1 if result == subsector
          count += 1
        end
      end

      (ok.to_f64 / count).should be >= 0.995
    end

    it "Point On Seg Side1" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        vertex1 = Vertex.new(Fixed.from_f64(start_x), Fixed.zero)
        vertex2 = Vertex.new(Fixed.from_f64(end_x - start_x), Fixed.zero)

        seg = Seg.new(
          vertex1,
          vertex2,
          Fixed.zero, Angle.ang0, nil, nil, nil, nil
        )

        x = Fixed.from_f64(point_x)

        y = Fixed.from_f64(front_side_y)
        Geometry.point_on_seg_side(x, y, seg).should eq 0

        y = Fixed.from_f64(back_side_y)
        Geometry.point_on_seg_side(x, y, seg).should eq 1
      end
    end

    it "Point On Seg Side2" do
      random = Random.new(666)
      1000.times do |i|
        start_y = +1 + 666 * random.next_float
        end_y = -1 - 666 * random.next_float

        point_y = 666 * random.next_float - 333
        front_side_x = -1 - 666 * random.next_float
        back_side_x = -front_side_x

        vertex1 = Vertex.new(Fixed.zero, Fixed.from_f64(start_y))
        vertex2 = Vertex.new(Fixed.zero, Fixed.from_f64(end_y - start_y))

        seg = Seg.new(
          vertex1,
          vertex2,
          Fixed.zero, Angle.ang0, nil, nil, nil, nil
        )

        y = Fixed.from_f64(point_y)

        x = Fixed.from_f64(front_side_x)
        Geometry.point_on_seg_side(x, y, seg).should eq 0

        x = Fixed.from_f64(back_side_x)
        Geometry.point_on_seg_side(x, y, seg).should eq 1
      end
    end

    it "Point On Seg Side3" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        100.times do |j|
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333

          vertex1 = Vertex.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta)))
          vertex2 = Vertex.new(
            vertex1.x + Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            vertex1.y + Fixed.from_f64((end_x - start_x) * Math.sin(theta)))

          seg = Seg.new(
            vertex1,
            vertex2,
            Fixed.zero, Angle.ang0, nil, nil, nil, nil
          )

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta))
          Geometry.point_on_seg_side(x, y, seg).should eq 0

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta))
          Geometry.point_on_seg_side(x, y, seg).should eq 1
        end
      end
    end

    it "Point On Line Side1" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        vertex1 = Vertex.new(Fixed.from_f64(start_x), Fixed.zero)
        vertex2 = Vertex.new(Fixed.from_f64(end_x - start_x), Fixed.zero)

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        x = Fixed.from_f64(point_x)

        y = Fixed.from_f64(front_side_y)
        Geometry.point_on_line_side(x, y, line).should eq 0

        y = Fixed.from_f64(back_side_y)
        Geometry.point_on_line_side(x, y, line).should eq 1
      end
    end

    it "Point On Line Side2" do
      random = Random.new(666)
      1000.times do |i|
        start_y = +1 + 666 * random.next_float
        end_y = -1 - 666 * random.next_float

        point_y = 666 * random.next_float - 333
        front_side_x = -1 - 666 * random.next_float
        back_side_x = -front_side_x

        vertex1 = Vertex.new(Fixed.zero, Fixed.from_f64(start_y))
        vertex2 = Vertex.new(Fixed.zero, Fixed.from_f64(end_y - start_y))

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        y = Fixed.from_f64(point_y)

        x = Fixed.from_f64(front_side_x)
        Geometry.point_on_line_side(x, y, line).should eq 0

        x = Fixed.from_f64(back_side_x)
        Geometry.point_on_line_side(x, y, line).should eq 1
      end
    end

    it "Point On Line Side3" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        100.times do |j|
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333

          vertex1 = Vertex.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta)))
          vertex2 = Vertex.new(
            vertex1.x + Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            vertex1.y + Fixed.from_f64((end_x - start_x) * Math.sin(theta)))

          line = LineDef.new(
            vertex1,
            vertex2,
            LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
          )

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta))
          Geometry.point_on_line_side(x, y, line).should eq 0

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta))
          Geometry.point_on_line_side(x, y, line).should eq 1
        end
      end
    end

    it "Box On Line Side1" do
      random = Random.new(666)
      1000.times do |i|
        radius = 33 + 33 * random.next_float

        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - radius - 666 * random.next_float
        back_side_y = -front_side_y
        crossing_y = radius * 1.9 * (random.next_float - 0.5)

        front_box = [
          Fixed.from_f64(front_side_y + radius),
          Fixed.from_f64(front_side_y - radius),
          Fixed.from_f64(point_x - radius),
          Fixed.from_f64(point_x + radius),
        ]

        back_box = [
          Fixed.from_f64(back_side_y + radius),
          Fixed.from_f64(back_side_y - radius),
          Fixed.from_f64(point_x - radius),
          Fixed.from_f64(point_x + radius),
        ]

        crossing_box = [
          Fixed.from_f64(crossing_y + radius),
          Fixed.from_f64(crossing_y - radius),
          Fixed.from_f64(point_x - radius),
          Fixed.from_f64(point_x + radius),
        ]

        vertex1 = Vertex.new(Fixed.from_f64(start_x), Fixed.zero)
        vertex2 = Vertex.new(Fixed.from_f64(end_x - start_x), Fixed.zero)

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        Geometry.box_on_line_side(front_box, line).should eq 0
        Geometry.box_on_line_side(back_box, line).should eq 1
        Geometry.box_on_line_side(crossing_box, line).should eq -1
      end
    end

    it "Box On Line Side2" do
      random = Random.new(666)
      1000.times do |i|
        radius = 33 + 33 * random.next_float

        start_y = +1 + 666 * random.next_float
        end_y = -1 - 666 * random.next_float

        point_y = 666 * random.next_float - 333
        front_side_x = -1 - radius - 666 * random.next_float
        back_side_x = -front_side_x
        crossing_x = radius * 1.9 * (random.next_float - 0.5)

        front_box = [
          Fixed.from_f64(point_y + radius),
          Fixed.from_f64(point_y - radius),
          Fixed.from_f64(front_side_x - radius),
          Fixed.from_f64(front_side_x + radius),
        ]

        back_box = [
          Fixed.from_f64(point_y + radius),
          Fixed.from_f64(point_y - radius),
          Fixed.from_f64(back_side_x - radius),
          Fixed.from_f64(back_side_x + radius),
        ]

        crossing_box = [
          Fixed.from_f64(point_y + radius),
          Fixed.from_f64(point_y - radius),
          Fixed.from_f64(crossing_x - radius),
          Fixed.from_f64(crossing_x + radius),
        ]

        vertex1 = Vertex.new(Fixed.zero, Fixed.from_f64(start_y))
        vertex2 = Vertex.new(Fixed.zero, Fixed.from_f64(end_y - start_y))

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        Geometry.box_on_line_side(front_box, line).should eq 0
        Geometry.box_on_line_side(back_box, line).should eq 1
        Geometry.box_on_line_side(crossing_box, line).should eq -1
      end
    end

    it "Box On Line Side3" do
      random = Random.new(666)
      1000.times do |i|
        radius = 33 + 33 * random.next_float

        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 1.5 * radius - 666 * random.next_float
        back_side_y = -front_side_y
        crossing_y = radius * 1.9 * (random.next_float - 0.5)

        100.times do |j|
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333

          front_box = [
            Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta) + radius),
            Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta) - radius),
            Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta) - radius),
            Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta) + radius),
          ]

          back_box = [
            Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta) + radius),
            Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta) - radius),
            Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta) - radius),
            Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta) + radius),
          ]

          crossing_box = [
            Fixed.from_f64(oy + point_x * Math.sin(theta) + crossing_y * Math.cos(theta) + radius),
            Fixed.from_f64(oy + point_x * Math.sin(theta) + crossing_y * Math.cos(theta) - radius),
            Fixed.from_f64(ox + point_x * Math.cos(theta) - crossing_y * Math.sin(theta) - radius),
            Fixed.from_f64(ox + point_x * Math.cos(theta) - crossing_y * Math.sin(theta) + radius),
          ]

          vertex1 = Vertex.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta))
          )

          vertex2 = Vertex.new(
            vertex1.x + Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            vertex1.y + Fixed.from_f64((end_x - start_x) * Math.sin(theta)),
          )

          line = LineDef.new(
            vertex1,
            vertex2,
            LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
          )

          Geometry.box_on_line_side(front_box, line).should eq 0
          Geometry.box_on_line_side(back_box, line).should eq 1
          Geometry.box_on_line_side(crossing_box, line).should eq -1
        end
      end
    end

    it "Point On Div Line Side1" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        vertex1 = Vertex.new(Fixed.from_f64(start_x), Fixed.zero)
        vertex2 = Vertex.new(Fixed.from_f64(end_x - start_x), Fixed.zero)

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        div_line = DivLine.new
        div_line.make_from(line)

        x = Fixed.from_f64(point_x)

        y = Fixed.from_f64(front_side_y)
        Geometry.point_on_div_line_side(x, y, div_line).should eq 0

        y = Fixed.from_f64(back_side_y)
        Geometry.point_on_div_line_side(x, y, div_line).should eq 1
      end
    end

    it "Point On Div Line Side2" do
      random = Random.new(666)
      1000.times do |i|
        start_y = +1 + 666 * random.next_float
        end_y = -1 - 666 * random.next_float

        point_y = 666 * random.next_float - 333
        front_side_x = -1 - 666 * random.next_float
        back_side_x = -front_side_x

        vertex1 = Vertex.new(Fixed.zero, Fixed.from_f64(start_y))
        vertex2 = Vertex.new(Fixed.zero, Fixed.from_f64(end_y - start_y))

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        div_line = DivLine.new
        div_line.make_from(line)

        y = Fixed.from_f64(point_y)

        x = Fixed.from_f64(front_side_x)
        Geometry.point_on_div_line_side(x, y, div_line).should eq 0

        x = Fixed.from_f64(back_side_x)
        Geometry.point_on_div_line_side(x, y, div_line).should eq 1
      end
    end

    it "Point On Div Line Side3" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        100.times do |j|
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333

          vertex1 = Vertex.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta)))
          vertex2 = Vertex.new(
            vertex1.x + Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            vertex1.y + Fixed.from_f64((end_x - start_x) * Math.sin(theta)))

          line = LineDef.new(
            vertex1,
            vertex2,
            LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
          )

          div_line = DivLine.new
          div_line.make_from(line)

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta))
          Geometry.point_on_div_line_side(x, y, div_line).should eq 0

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta))
          Geometry.point_on_div_line_side(x, y, div_line).should eq 1
        end
      end
    end

    it "Aprox Distance" do
      random = Random.new(666)
      1000.times do |i|
        dx = 666 * random.next_float - 333
        dy = 666 * random.next_float - 333

        adx = dx.abs
        ady = dy.abs
        expected = adx + ady - Math.min(adx, ady) / 2

        actual = Geometry.aprox_distance(Fixed.from_f64(dx), Fixed.from_f64(dy))

        expected.should be_close(actual.to_f64, 1.0E-3)
      end
    end

    it "Point On Div Line Side1" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        vertex1 = Vertex.new(Fixed.from_f64(start_x), Fixed.zero)
        vertex2 = Vertex.new(Fixed.from_f64(end_x - start_x), Fixed.zero)

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        div_line = DivLine.new
        div_line.make_from(line)

        node = Node.new(
          Fixed.from_f64(start_x),
          Fixed.zero,
          Fixed.from_f64(end_x - start_x),
          Fixed.zero,
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          0, 0
        )

        x = Fixed.from_f64(point_x)

        y = Fixed.from_f64(front_side_y)
        Geometry.div_line_side(x, y, div_line).should eq 0
        Geometry.div_line_side(x, y, node).should eq 0

        y = Fixed.from_f64(back_side_y)
        Geometry.div_line_side(x, y, div_line).should eq 1
        Geometry.div_line_side(x, y, node).should eq 1
      end
    end

    it "Point On Div Line Side2" do
      random = Random.new(666)
      1000.times do |i|
        start_y = +1 + 666 * random.next_float
        end_y = -1 - 666 * random.next_float

        point_y = 666 * random.next_float - 333
        front_side_x = -1 - 666 * random.next_float
        back_side_x = -front_side_x

        vertex1 = Vertex.new(Fixed.zero, Fixed.from_f64(start_y))
        vertex2 = Vertex.new(Fixed.zero, Fixed.from_f64(end_y - start_y))

        line = LineDef.new(
          vertex1,
          vertex2,
          LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
        )

        div_line = DivLine.new
        div_line.make_from(line)

        node = Node.new(
          Fixed.zero,
          Fixed.from_f64(start_y),
          Fixed.zero,
          Fixed.from_f64(end_y - start_y),
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
          0, 0
        )

        y = Fixed.from_f64(point_y)

        x = Fixed.from_f64(front_side_x)
        Geometry.div_line_side(x, y, div_line).should eq 0
        Geometry.div_line_side(x, y, node).should eq 0

        x = Fixed.from_f64(back_side_x)
        Geometry.div_line_side(x, y, div_line).should eq 1
        Geometry.div_line_side(x, y, node).should eq 1
      end
    end

    it "Point On Div Line Side3" do
      random = Random.new(666)
      1000.times do |i|
        start_x = -1 - 666 * random.next_float
        end_x = +1 + 666 * random.next_float

        point_x = 666 * random.next_float - 333
        front_side_y = -1 - 666 * random.next_float
        back_side_y = -front_side_y

        100.times do |j|
          theta = 2 * Math::PI * random.next_float
          ox = 666 * random.next_float - 333
          oy = 666 * random.next_float - 333

          vertex1 = Vertex.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta)))
          vertex2 = Vertex.new(
            vertex1.x + Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            vertex1.y + Fixed.from_f64((end_x - start_x) * Math.sin(theta)))

          line = LineDef.new(
            vertex1,
            vertex2,
            LineFlags.new(0), LineSpecial.new(0), 0_i16, nil, nil
          )

          div_line = DivLine.new
          div_line.make_from(line)

          node = Node.new(
            Fixed.from_f64(ox + start_x * Math.cos(theta)),
            Fixed.from_f64(oy + start_x * Math.sin(theta)),
            Fixed.from_f64((end_x - start_x) * Math.cos(theta)),
            Fixed.from_f64((end_x - start_x) * Math.sin(theta)),
            Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
            Fixed.zero, Fixed.zero, Fixed.zero, Fixed.zero,
            0, 0
          )

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - front_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + front_side_y * Math.cos(theta))
          Geometry.div_line_side(x, y, div_line).should eq 0
          Geometry.div_line_side(x, y, node).should eq 0

          x = Fixed.from_f64(ox + point_x * Math.cos(theta) - back_side_y * Math.sin(theta))
          y = Fixed.from_f64(oy + point_x * Math.sin(theta) + back_side_y * Math.cos(theta))
          Geometry.div_line_side(x, y, div_line).should eq 1
          Geometry.div_line_side(x, y, node).should eq 1
        end
      end
    end
  end
end
