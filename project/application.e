note
	description: "A test and demo for the Neural Network Library"
	author: "Louis Marchand"
	date: "Thu, 07 Jul 2016 19:30:43 +0000"
	revision: "0.1"

class
	APPLICATION

inherit
	ARGUMENTS

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
			l_label_learning_file_name, l_image_learning_file_name:READABLE_STRING_GENERAL
			l_label_testing_file_name, l_image_testing_file_name:READABLE_STRING_GENERAL
			l_learning_set, l_testing_set:IMAGES_SET
		do
			l_label_learning_file_name := "train-labels-idx1-ubyte"
			l_image_learning_file_name := "train-images-idx3-ubyte"
--			l_label_learning_file_name := "t10k-labels-idx1-ubyte"
--			l_image_learning_file_name := "t10k-images-idx3-ubyte"
			l_label_testing_file_name := "t10k-labels-idx1-ubyte"
			l_image_testing_file_name := "t10k-images-idx3-ubyte"
			create l_learning_set.make(l_label_learning_file_name, l_image_learning_file_name)
			create l_testing_set.make_with_neural_network(
									l_label_testing_file_name, l_image_testing_file_name,
									l_learning_set.neural_network
								)
			if not l_learning_set.has_error and not l_testing_set.has_error then
				l_learning_set.learning
				l_testing_set.testing
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
