# Azure PostgreSQL compatibility fix
if defined?(ActiveRecord)
  module AzurePostgreSQLCompatibility
    # List of extensions not supported by Azure PostgreSQL
    UNSUPPORTED_EXTENSIONS = %w[
      btree_gin
      pg_catalog.plpgsql
      plpgsql
    ].freeze

    def enable_extension(name)
      if UNSUPPORTED_EXTENSIONS.include?(name)
        begin
          super
        rescue ActiveRecord::StatementInvalid => e
          if e.message.include?("not allow-listed") || 
             e.message.include?("Azure Database for PostgreSQL") ||
             e.message.include?("FeatureNotSupported")
            Rails.logger.warn "Skipping #{name} extension - not supported on Azure PostgreSQL"
            return
          else
            raise e
          end
        end
      else
        super
      end
    end

    def execute(sql, name = nil)
      if sql.to_s.match?(/CREATE EXTENSION.*(btree_gin|plpgsql)/i)
        Rails.logger.warn "Skipping extension creation: #{sql}"
        return
      end
      super
    end
  end

  # Apply the patch
  ActiveRecord::Schema.prepend(AzurePostgreSQLCompatibility)
  ActiveRecord::Migration.prepend(AzurePostgreSQLCompatibility) if defined?(ActiveRecord::Migration)
  
  if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(AzurePostgreSQLCompatibility)
  end
end
