note
	description: "Summary description for {ENGINE}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	ENGINE

inherit
	GAME_LIBRARY_SHARED

create
	make

feature {NONE} -- Initialization

	make(
			a_label_learning_file, a_image_learning_file, a_label_testing_file, a_image_testing_file:READABLE_STRING_GENERAL
		)
		local
			l_window_builder: GAME_WINDOW_SURFACED_BUILDER
			l_layer_count:ARRAYED_LIST[INTEGER]
			l_pixel_format:GAME_PIXEL_FORMAT
		do
			has_error := False
			images_width := 1
			images_height := 1
			label_learning_file_name := a_label_learning_file
			image_learning_file_name := a_image_learning_file
			label_testing_file_name := a_label_testing_file
			image_testing_file_name := a_image_testing_file
			init_learning_informations
			init_testing_informations
			create label_learning_file.make_with_name (label_learning_file_name)
			create image_learning_file.make_with_name (image_learning_file_name)
			create label_testing_file.make_with_name (label_testing_file_name)
			create image_testing_file.make_with_name (image_testing_file_name)
			if
					(label_learning_file.exists and then label_learning_file.is_readable)
				and
					(image_learning_file.exists and then image_learning_file.is_readable)
				and
					(label_testing_file.exists and then label_testing_file.is_readable)
				and
					(image_testing_file.exists and then image_testing_file.is_readable)
			then
				label_learning_file.open_read
				image_learning_file.open_read
				label_testing_file.open_read
				image_testing_file.open_read
			else
				has_error := True
			end
			create l_window_builder
			l_window_builder.set_dimension (200, 200)
			window := l_window_builder.generate_window
			create l_pixel_format
			l_pixel_format.set_rgb888
			create image_surface.make_for_pixel_format (l_pixel_format, images_width, images_height)
			if not image_surface.is_open then
				has_error := True
			end
			create background_color.make_rgb (0, 0, 0)
			create foreground_color.make_rgb (255, 255, 255)
			create font.make ("font.ttf", images_height)
			if font.is_openable then
				font.open
				if not font.is_open then
					has_error := True
				end
			else
				has_error := True
			end
			create l_layer_count.make_from_array (<<images_height * images_width, 15, 10>>)
			create neural_network.make (l_layer_count)
		end

feature -- Access

	has_error:BOOLEAN

	images_learning_count:INTEGER

	images_testing_count:INTEGER

	images_width:INTEGER

	images_height:INTEGER

	run
		require
			No_Error: not has_error
		do
			game_library.quit_signal_actions.extend (agent on_quit)
			learning
			testing
		end

	label_learning_file_name:READABLE_STRING_GENERAL

	label_learning_file:RAW_FILE

	image_learning_file_name:READABLE_STRING_GENERAL

	image_learning_file:RAW_FILE

	label_testing_file_name:READABLE_STRING_GENERAL

	label_testing_file:RAW_FILE

	image_testing_file_name:READABLE_STRING_GENERAL

	image_testing_file:RAW_FILE

	window:GAME_WINDOW_SURFACED

	image_surface:GAME_SURFACE

	background_color: GAME_COLOR

	foreground_color:GAME_COLOR

	font:TEXT_FONT

	neural_network:NEURAL_NETWORK

feature {NONE} -- Initialization

	learning
		local
			l_image_values:ARRAYED_LIST[NATURAL_8]
			l_index1:INTEGER
		do
			create l_image_values.make_filled (images_height * images_width)
			label_learning_file.go (8)
			image_learning_file.go (16)
			from
				l_index1 := 1
				must_quit := False
			until
				l_index1 > images_learning_count or must_quit
			loop
				label_learning_file.read_natural_8
				across 1 |..| (images_height * images_width) as la_index2 loop
					image_learning_file.read_natural_8
					l_image_values.put_i_th (image_learning_file.last_natural_8, la_index2.item)
				end
				show_image(label_learning_file.last_natural_8, l_image_values)
				update_neural_network(label_learning_file.last_natural_8, l_image_values)
				l_index1 := l_index1 + 1
				game_library.update_events
			end
		end

	testing
		local
			l_image_values:ARRAYED_LIST[NATURAL_8]
			l_index1:INTEGER
			l_output:LIST[REAL_64]
		do
			create l_image_values.make_filled (images_height * images_width)
			label_testing_file.go (8)
			image_testing_file.go (16)
			from
				l_index1 := 1
				must_quit := False
			until
				l_index1 > images_testing_count or must_quit
			loop
				label_testing_file.read_natural_8
				across 1 |..| (images_height * images_width) as la_index2 loop
					image_testing_file.read_natural_8
					l_image_values.put_i_th (image_testing_file.last_natural_8, la_index2.item)
				end
				show_image(label_testing_file.last_natural_8, l_image_values)
				l_output := use_neural_network(l_image_values)
				print("Index: " + l_index1.out + " | value: " + label_testing_file.last_natural_8.out + " | Output: (")
				across l_output as la_output loop
					print(la_output.item.rounded.out + ", ")
				end
				print(")%N")
				l_index1 := l_index1 + 1
				game_library.update_events
			end
		end

	must_quit:BOOLEAN

	on_quit(a_timestamp:NATURAL)
		do
			must_quit := True
		end

	show_image(a_label:NATURAL_8; a_image_values:LIST[NATURAL_8])
		require
			a_image_values.count = images_height * images_width
		local
			l_value:NATURAL_8
			l_text_surface:TEXT_SURFACE_SHADED
		do
			create l_text_surface.make (a_label.out + " -> ", font, foreground_color, background_color)
			image_surface.lock
			across 1 |..| images_height as la_row loop
				across 1 |..| images_width as la_column loop
					l_value := a_image_values.at (((la_row.item - 1) * images_width) + la_column.item)
					image_surface.pixels.set_pixel (create {GAME_COLOR}.make_rgb (l_value, l_value, l_value), la_row.item, la_column.item)
				end
			end
			image_surface.unlock
			window.surface.draw_rectangle (background_color, 0, 0, window.surface.width, window.surface.height)
			window.surface.draw_surface (l_text_surface, 10, 10)
			window.surface.draw_surface (image_surface, 10 + l_text_surface.width, 10 - (image_surface.height - l_text_surface.height))
			window.update
		end

	update_neural_network(a_label:NATURAL_8; a_image_values:LIST[NATURAL_8])
		local
			l_input, l_expected_output:ARRAYED_LIST[REAL_64]
		do
			create l_input.make (a_image_values.count)
			across a_image_values as la_image_values loop
				l_input.extend (la_image_values.item / 255)
			end
			create l_expected_output.make_filled (10)
			l_expected_output.put_i_th (1.0, a_label + 1)
			neural_network.learn_back_propagate (l_input, l_expected_output)
		end

	use_neural_network(a_image_values:LIST[NATURAL_8]):LIST[REAL_64]
		local
			l_input:ARRAYED_LIST[REAL_64]
		do
			create l_input.make (a_image_values.count)
			across a_image_values as la_image_values loop
				l_input.extend (la_image_values.item / 255)
			end
			Result := neural_network.use_network (l_input)
		end

	init_learning_informations
		local
			l_label_file, l_image_file:GAME_FILE
		do
			create l_label_file.make (label_learning_file_name)
			create l_image_file.make (image_learning_file_name)
			if
					(l_label_file.exists and then l_label_file.is_readable)
				and
					(l_image_file.exists and then l_image_file.is_readable)
			then
				l_label_file.open_read
				l_image_file.open_read
				l_label_file.read_natural_32_big_endian
				l_image_file.read_natural_32_big_endian
				if
						l_label_file.last_natural_32.as_integer_32 = 2049
					and
						l_image_file.last_natural_32.as_integer_32 = 2051
				then
					l_label_file.read_natural_32_big_endian
					images_learning_count := l_label_file.last_natural_32.as_integer_32
					l_image_file.read_natural_32_big_endian
					if l_image_file.last_natural_32.as_integer_32 ~ images_learning_count then
						l_image_file.read_natural_32_big_endian
						images_height := l_image_file.last_natural_32.as_integer_32
						l_image_file.read_natural_32_big_endian
						images_width := l_image_file.last_natural_32.as_integer_32
					else
						has_error := True
					end
				else
					has_error := True
				end
			else
				has_error := True
			end
		end

	init_testing_informations
		local
			l_label_file, l_image_file:GAME_FILE
		do
			create l_label_file.make (label_testing_file_name)
			create l_image_file.make (image_testing_file_name)
			if
					(l_label_file.exists and then l_label_file.is_readable)
				and
					(l_image_file.exists and then l_image_file.is_readable)
			then
				l_label_file.open_read
				l_image_file.open_read
				l_label_file.read_natural_32_big_endian
				l_image_file.read_natural_32_big_endian
				if
						l_label_file.last_natural_32.as_integer_32 = 2049
					and
						l_image_file.last_natural_32.as_integer_32 = 2051
				then
					l_label_file.read_natural_32_big_endian
					images_testing_count := l_label_file.last_natural_32.as_integer_32
					l_image_file.read_natural_32_big_endian
					if l_image_file.last_natural_32.as_integer_32 ~ images_testing_count then
						l_image_file.read_natural_32_big_endian
						if images_height /~ l_image_file.last_natural_32.as_integer_32 then
							has_error := True
						end
						l_image_file.read_natural_32_big_endian
						if images_width /~ l_image_file.last_natural_32.as_integer_32 then
							has_error := True
						end
					else
						has_error := True
					end
				else
					has_error := True
				end
			else
				has_error := True
			end
		end

end
