# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Todo < Base
      sig do
        params(
          todo_file: String,
          file_header: T::Boolean,
          default_command: String,
          file_writer: Thor::Actions
        ).void
      end
      def initialize(todo_file:, file_header:, default_command:, file_writer: FileWriter.new)
        @todo_file = todo_file
        @file_header = file_header

        super(default_command: default_command, file_writer: file_writer)
      end

      sig { override.void }
      def generate
        say("Finding all unresolved constants, this may take a few seconds... ")

        # Clean all existing unresolved constants before regenerating the list
        # so Sorbet won't grab them as already resolved.
        File.delete(@todo_file) if File.exist?(@todo_file)

        rbi_string = compile
        if rbi_string.empty?
          say("Nothing to do", :green)
          return
        end

        content = String.new
        content << rbi_header(
          "#{@default_command} todo",
          reason: "unresolved constants",
          strictness: "false"
        )
        content << rbi_string
        content << "\n"

        say("Done", :green)
        create_file(@todo_file, content, verbose: false)

        name = set_color(@todo_file, :yellow, :bold)
        say("\nAll unresolved constants have been written to #{name}.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
      end

      sig { params(command: String, reason: T.nilable(String), strictness: T.nilable(String)).returns(String) }
      def rbi_header(command, reason: nil, strictness: nil)
        statement = <<~HEAD
          # DO NOT EDIT MANUALLY
          # This is an autogenerated file for #{reason}.
          # Please instead update this file by running `#{command}`.
        HEAD

        sigil = <<~SIGIL if strictness
          # typed: #{strictness}
        SIGIL

        if @file_header
          [statement, sigil].compact.join("\n").strip.concat("\n\n")
        elsif sigil
          sigil.strip.concat("\n\n")
        else
          ""
        end
      end

      sig do
        returns(String)
      end
      def compile
        list_todos.each_line.map do |line|
          next if line.include?("<") || line.include?("class_of")
          "module #{line.strip.gsub("T.untyped::", "")}; end"
        end.compact.join("\n")
      end

      # Taken from https://github.com/sorbet/sorbet/blob/master/gems/sorbet/lib/todo-rbi.rb
      sig { returns(String) }
      def list_todos
        Tapioca::Compilers::Sorbet.run(
          "--print=missing-constants",
          "--stdout-hup-hack",
          "--no-error-count"
        ).strip
      end
    end
  end
end
