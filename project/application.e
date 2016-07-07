note
	description: "project application root class"
	date: "$Date$"
	revision: "$Revision$"

class
	APPLICATION

inherit
	ARGUMENTS
	GAME_LIBRARY_SHARED
	TEXT_LIBRARY_SHARED

create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
			l_engine:detachable ENGINE
			l_label_learning_file, l_image_learning_file, l_label_testing_file, l_image_testing_file:READABLE_STRING_GENERAL
		do
			game_library.enable_video
			text_library.enable_text
--			l_label_learning_file := "train-labels-idx1-ubyte"
--			l_image_learning_file := "train-images-idx3-ubyte"
			l_label_learning_file := "t10k-labels-idx1-ubyte"
			l_image_learning_file := "t10k-images-idx3-ubyte"
			l_label_testing_file := "t10k-labels-idx1-ubyte"
			l_image_testing_file := "t10k-images-idx3-ubyte"
			create l_engine.make(l_label_learning_file, l_image_learning_file, l_label_testing_file, l_image_testing_file)
			if not l_engine.has_error then
				l_engine.run
				l_engine.window.close
			end
			l_engine := Void
			game_library.clear_all_events
			game_library.quit_library
			text_library.quit_library
		end

end
