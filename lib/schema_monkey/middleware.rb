module SchemaMonkey
  module Middleware

    class Base
      def initialize(app)
        @app = app
      end
      def continue(env)
        @app.call env
      end
    end

    module Stack
      def stack
        @stack ||= ::Middleware::Builder.new do
          use Root
        end
      end

      def append(middleware)
        stack.insert_before(Root, middleware)
      end

      def prepend(middleware)
        stack.insert(0, middleware)
      end

      def start(*args, &block)
        env = self.const_get(:Env).new(*args)
        env.instance_variable_set('@root', block)
        stack.call(env)
      end

      class Root < Base
        def call(env)
          env.instance_variable_get('@root').call(env)
        end
      end
    end

    module Query
      module ExecCache
        extend Stack
        Env = KeyStruct[:connection, :sql, :name, :binds]
      end

      module Tables
        extend Stack
        # :database and :like are only for mysql
        # :table_name is only for sqlite3
        Env = KeyStruct[:connection, :query_name, :table_name, :database, :like, tables: []]
      end

      module Indexes
        extend Stack
        Env = KeyStruct[:connection, :table_name, :query_name, index_definitions: []]
      end
    end

    module Migration

      module Column
        extend Stack
        Env = KeyStruct[:caller, :operation, :table_name, :column_name, :type, :options]
      end

      module ColumnOptionsSql
        extend Stack
        Env = KeyStruct[:caller, :connection, :sql, :options]
      end

      module Index
        extend Stack
        Env = KeyStruct[:caller, :operation, :table_name, :column_names, :options]
      end

      module IndexComponentsSql
        extend Stack
        Sql = KeyStruct[:name, :type, :columns, :options, :algorithm, :using]
        Env = KeyStruct[:connection, :table_name, :column_names, :options, sql: Sql.new]
      end

    end

    module Dumper
      module Extensions
        extend Stack
        Env = KeyStruct[:dumper, :connection, :extensions]
      end
      module Tables
        extend Stack
        Env = KeyStruct[:dumper, :connection, :dump]
      end
      module Table
        extend Stack
        Env = KeyStruct[:dumper, :connection, :dump, :table]
      end
    end

    module Model
      module Columns
        extend Stack
        Env = KeyStruct[:model, :columns]
      end
      module ResetColumnInformation
        extend Stack
        Env = KeyStruct[:model]
      end
    end


  end
end