require_relative './callback_std'
require_relative '../comicpub'
require_relative '../utils'
require 'pathname'
require 'thread'
require 'tk'

module Window   
   @@root = TkRoot.new 
   @@root.title 'Comic-pub'
   @@split_value = TkVariable.new('PRESERVE')
   @@manga_mode = TkVariable.new(false)
   @@add_toc = TkVariable.new(false)
   @@to_mobi = TkVariable.new(false)
   @@output_filename = ''
   @@strings = { :no_files => 'No selected files' }
   @@worker_thread = nil

   def self.run
      self.init_component
      # for anything that have to be print from another thread use this, otherwise use @@label_message.text
      $log_stdout = CallbackStd.new proc { |text| @@label_message.text = text }
      Tk.mainloop
   end

private
   def self.start_conversion
      @@convert_btn.state = 'disabled'
      @@abort_btn.state = 'normal'
   end

   def self.end_conversion
      @@convert_btn.state = 'normal'
      @@abort_btn.state = 'disabled'
      self.clear_items
   end

   def self.clear_items
      while @@convert_list.size != 0
         @@convert_list.delete(0)
      end
   end

   def self.convert_all
      return if @@convert_list.size == 0
      self.start_conversion

      args = {}
      args[:manga] = true if @@manga_mode.bool
      args[:toc] = true if @@add_toc.bool
      # the name must not be global, or else all the files will be replaced
      # args[:output] = @output_filename if @output_filename != '' 
      Thread.new do
         files = @@convert_list.get(0, @@convert_list.size)
         files.each do |file|
            args[:filename] = Pathname.new(file)

            $log_stdout << "Converting #{file}..."

            epub_name = create_epub(args)
            # rewrite to_mobi to the ui known if was successful
            to_mobi(epub_name) if @@to_mobi.bool
         end
         self.end_conversion
         $log_stdout << 'Convertion finished'
      end  
   end

   def self.abort_conversion
      return if @@worker_thread == nil
      @@worker_thread.kill
      @@worker_thread = nil
      self.end_conversion
      @@label_message.text = 'Convertion aborted'
   end

   def self.open_item(is_file)
      filetypes = [
         ['CBZ archives', '*.cbz'],
         ['ZIP archives', '*.zip']
      ]
      filename = is_file ? Tk.getOpenFile('filetypes' => filetypes) : Tk.chooseDirectory
      @@convert_list.insert(0, filename) if filename != ''
      @@label_message.text "#{filename} added"
   end

   def self.remove_item
      arr = @@convert_list.curselection
      @@convert_list.delete(arr[0]) if arr != []

      if @@convert_list.size == 0
         @@label_message.text = @@strings[:no_files]
      elsif arr != []
         @@label_message.text = "#{arr[0]} removed"
      end
   end

   
   def self.init_component
      main_frame = TkFrame.new.pack
      frame_left = TkFrame.new(main_frame) do
         pack('side' => 'left', 'fill' => 'y')
      end

      frame_right = TkFrame.new(main_frame)  do
         pack('side' => 'right', 'fill' => 'y')
      end

      @@label_message = TkLabel.new do
         text @@strings[:no_files]
         pack('side' => 'bottom', 'anchor' => 'w', 'fill' => 'both')
      end

      frame_add = TkFrame.new(frame_left)  do
         pack('side' => 'top', 'fill' => 'x')
      end

      TkButton.new(frame_add) do
         text '+ file'
         command proc { Window::open_item is_file = true }
         pack 'side' => 'left', 'fill' => 'x'
      end

      TkButton.new(frame_add) do
         text '+ folder'
         command proc { Window::open_item is_file = false }
         pack 'side' => 'left', 'fill' => 'x'
      end
      
      TkButton.new(frame_add) do
         text '- del'
         command proc { Window::remove_item }
         pack 'side' => 'right', 'fill' => 'x'
      end

      # TODO: Enable when is it possible to edit each entry alone
      @@convert_list = TkListbox.new(frame_left).pack('fill' => 'both')

      TkLabel.new(frame_right) { text 'Output file' }.pack
      entry_output = TkEntry.new(frame_right).state('disabled').pack
      label_frame = TkLabelFrame.new(frame_right).text("Double spread handling").pack
      check_manga = TkCheckButton.new(frame_right) do
         text 'Manga mode (right-to-left)'
         variable @@manga_mode
         borderwidth 0
         pack
      end

      check_toc = TkCheckButton.new(frame_right) do
         text 'Add TOC at the end'
         variable @@add_toc
         borderwidth 0
         pack
      end

      check_mobi = TkCheckButton.new(frame_right) do
         text 'Convert to mobi'
         variable @@to_mobi
         borderwidth 0
         pack
      end

      button_frame = TkFrame.new(frame_right).pack

      @@convert_btn = TkButton.new(button_frame) do
         text 'Convert all'
         command proc{ Window::convert_all }
         pack 'side' => 'left'
      end

      @@abort_btn = TkButton.new(button_frame) do
         text 'Abort'
         command proc{ Window::abort_conversion }
         state 'disabled'
         pack 'side' => 'right'
      end

      TkRadioButton.new(label_frame) do
         text 'none'
         value 'PRESERVE'
         variable @@split_value
         tristatevalue 0
         anchor 'w'
         pack
      end

      TkRadioButton.new(label_frame) do
         text 'split'
         value 'SPLIT'
         variable @@split_value
         tristatevalue 1
         anchor 'w'
         pack
      end

      TkRadioButton.new(label_frame) do
         text 'both'
         value 'BOTH'
         variable @@split_value
         tristatevalue 2
         anchor 'w'
         pack
      end
   end
end

Window.run
