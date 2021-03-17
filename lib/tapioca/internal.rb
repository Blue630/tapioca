# typed: strict
# frozen_string_literal: true

require "tapioca"
require "tapioca/loader"
require "tapioca/constant_locator"
require "tapioca/config"
require "tapioca/config_builder"
require "tapioca/generator"
require "tapioca/cli"
require "tapioca/gemfile"
require "tapioca/compilers/sorbet"
require "tapioca/compilers/requires_compiler"
require "tapioca/compilers/symbol_table_compiler"
require "tapioca/compilers/symbol_table/symbol_generator"
require "tapioca/compilers/symbol_table/symbol_loader"
require "tapioca/compilers/todos_compiler"
require "tapioca/compilers/dsl_compiler"