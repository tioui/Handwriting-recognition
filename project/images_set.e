note
	description: "All information about a set of image used in a {NEURAL_NETWORK}"
	author: "Louis Marchand"
	date: "Thu, 07 Jul 2016 19:30:43 +0000"
	revision: "0.1"

class
	IMAGES_SET

create
	make,
	make_with_neural_network

feature {NONE} -- Initialization

	make(a_label_file_name, a_image_file_name:READABLE_STRING_GENERAL)
			-- Initialization of `Current' using `a_label_file_name' as label set file and
			-- `a_image_file_name' as image pixel set. `neural_network' will be created.
		local
			l_layer_count:ARRAYED_LIST[INTEGER]
		do
			initialize(a_label_file_name, a_image_file_name)
			create l_layer_count.make_from_array (<<images_height * images_width, 15, 10>>)
			create neural_network.make (l_layer_count)
		end

	make_with_neural_network(a_label_file_name, a_image_file_name:READABLE_STRING_GENERAL; a_neural_network:NEURAL_NETWORK)
			-- Initialization of `Current' using `a_label_file_name' as label set file and
			-- `a_image_file_name' as image pixel set. `neural_network' will be set to `a_neural_network'.
		do
			initialize(a_label_file_name, a_image_file_name)
			neural_network := a_neural_network
		end

	initialize(a_label_file_name, a_image_file_name:READABLE_STRING_GENERAL)
			-- Initialization of `Current' using `a_label_file_name' as label set file and
			-- `a_image_file_name' as image pixel set. No `neural_network' will be created.
		do
			has_error := False
			images_width := 1
			images_height := 1
			create label_file.make_with_name (a_label_file_name)
			create image_file.make_with_name (a_image_file_name)
			if
					(label_file.exists and then label_file.is_readable)
				and
					(image_file.exists and then image_file.is_readable)
			then
				label_file.open_read
				image_file.open_read
				init_informations
			else
				has_error := True
			end
		end

feature -- Access

	has_error:BOOLEAN
			-- An error has occured while creating `Current'

	images_count:INTEGER
			-- The number of images in `Current'

	images_width, images_height:INTEGER
			-- The dimension of a single image

	label_file:RAW_FILE
			-- The file containing the label informations for `Current'

	image_file:RAW_FILE
			-- The file containing the images of `Current'

	neural_network:NEURAL_NETWORK
			-- The {NEURAL_NETWORK} used to recognise images

	learning
			-- Use `Current' to make the `neural_network' learne handwriting recognition
		require
			No_Error: not has_error
		local
			l_image_values:ARRAYED_LIST[NATURAL_8]
		do
			create l_image_values.make_filled (images_height * images_width)
			label_file.go (8)
			image_file.go (16)
			across 1 |..| images_count as la_index1 loop
				print("Learning: " + la_index1.item.out + "/" + images_count.out + "%N")
				label_file.read_natural_8
				across 1 |..| (images_height * images_width) as la_index2 loop
					image_file.read_natural_8
					l_image_values.put_i_th (image_file.last_natural_8, la_index2.item)
				end
				update_neural_network(label_file.last_natural_8, l_image_values)
			end
		end

	testing
			-- Use `Current' to make the `neural_network' recognise handwriting
		require
			No_Error: not has_error
		local
			l_image_values:ARRAYED_LIST[NATURAL_8]
			l_output:LIST[REAL_64]
			l_index:INTEGER
			l_value:REAL_64
		do
			create l_image_values.make_filled (images_height * images_width)
			label_file.go (8)
			image_file.go (16)
			across 1 |..| images_count as la_index1 loop
				label_file.read_natural_8
				across 1 |..| (images_height * images_width) as la_index2 loop
					image_file.read_natural_8
					l_image_values.put_i_th (image_file.last_natural_8, la_index2.item)
				end
				l_output := use_neural_network(l_image_values)
				l_value := 0.0
				l_index := 0
				print("Output values: (")
				from
					l_output.start
				until
					l_output.exhausted
				loop
					print(l_output.item.out + ", ")
					if l_output.item > l_value then
						l_value := l_output.item
						l_index := l_output.index
					end
					l_output.forth
				end
				print(")%NIndex: " + la_index1.item.out + " | value: " + label_file.last_natural_8.out + " | Recognition: " + l_index.out + "%N")
			end
		end

feature {NONE} -- Initialization

	natural_32_big_to_little_endian(a_value:NATURAL_32):NATURAL_32
			-- Convert a big-endian `a_value' to little-endian
		do
			Result := a_value.bit_shift_right (24)
			Result := Result.bit_or (a_value.bit_shift_right (8).bit_and ({NATURAL_32}0x0000FF00))
			Result := Result.bit_or (a_value.bit_shift_left (8).bit_and ({NATURAL_32}0x00FF0000))
			Result := Result.bit_or (a_value.bit_shift_left (24).bit_and ({NATURAL_32}0xFF000000))
		end

	update_neural_network(a_label:NATURAL_8; a_image_values:LIST[NATURAL_8])
			-- Use the image gray scaled pixel in `a_image_values' to learned the `neural_network'
			-- how to recognise the digits `a_label'
		local
			l_input, l_expected_output:ARRAYED_LIST[REAL_64]
		do
			create l_input.make (a_image_values.count)
			across a_image_values as la_image_values loop
				l_input.extend (la_image_values.item / {NATURAL_8}255)
			end
			create l_expected_output.make_filled (10)
			l_expected_output.put_i_th (1.0, a_label + 1)
			neural_network.learn_back_propagate (l_input, l_expected_output)
		end

	use_neural_network(a_image_values:LIST[NATURAL_8]):LIST[REAL_64]
			-- Use the `neral_network' to recognise the image gray scaled pixel in `a_image_values'.
			-- The resulting {LIST} contain 10 element (from 1 to 10). The element 1 is the recognition probability
			-- of the digits 0, the element 2, of digits 1, etc. The values must be between 0 and 1. More a value is
			-- close to 1, the more probable the associated digits is the recognition of the image.
		local
			l_input:ARRAYED_LIST[REAL_64]
		do
			create l_input.make (a_image_values.count)
			across a_image_values as la_image_values loop
				l_input.extend (la_image_values.item / {NATURAL_8}255)
			end
			Result := neural_network.use_network (l_input)
		end

	init_informations
			-- Extract  informations from the `label_file' and `image_file'
		require
			Is_Label_File_Valid: label_file.is_open_read
			Is_Image_File_Valid: image_file.is_open_read
		do
			label_file.read_natural_32
			image_file.read_natural_32
			if
					natural_32_big_to_little_endian (label_file.last_natural_32).as_integer_32 = 2049
				and
					natural_32_big_to_little_endian (image_file.last_natural_32).as_integer_32 = 2051
			then
				label_file.read_natural_32
				images_count := natural_32_big_to_little_endian (label_file.last_natural_32).as_integer_32
				image_file.read_natural_32
				if natural_32_big_to_little_endian (image_file.last_natural_32).as_integer_32 ~ images_count then
					image_file.read_natural_32
					images_height := natural_32_big_to_little_endian (image_file.last_natural_32).as_integer_32
					image_file.read_natural_32
					images_width := natural_32_big_to_little_endian (image_file.last_natural_32).as_integer_32
				else
					has_error := True
				end
			else
				has_error := True
			end
		end

note
    license: "[
            Copyright (C) 2016 Louis Marchand

            This program is free software: you can redistribute it and/or modify
            it under the terms of the GNU General Public License as published by
            the Free Software Foundation, either version 3 of the License, or
            (at your option) any later version.

            This program is distributed in the hope that it will be useful,
            but WITHOUT ANY WARRANTY; without even the implied warranty of
            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
            GNU General Public License for more details.

            You should have received a copy of the GNU General Public License
            along with this program.  If not, see <http://www.gnu.org/licenses/>.
        ]"

end
