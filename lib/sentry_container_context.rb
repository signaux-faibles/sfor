module SentryContainerContext
  ROLE_ENV = "SENTRY_CONTAINER_ROLE"

  WORKER_PROGRAM_NAMES = %w[jobs].freeze
  WORKER_ARGUMENTS = %w[jobs solid_queue].freeze

  module_function

  def tags(program_name: $PROGRAM_NAME, argv: ARGV, env: ENV)
    { container_role: role(program_name:, argv:, env:) }
  end

  def role(program_name: $PROGRAM_NAME, argv: ARGV, env: ENV)
    env_value(env, ROLE_ENV) || inferred_role(program_name:, argv:)
  end

  def inferred_role(program_name:, argv:)
    return "worker" if worker_program?(program_name)
    return "worker" if worker_argument?(argv)

    "web"
  end

  def worker_program?(program_name)
    WORKER_PROGRAM_NAMES.include?(File.basename(program_name.to_s))
  end

  def worker_argument?(argv)
    argv.any? do |argument|
      argument = argument.to_s

      WORKER_ARGUMENTS.include?(argument) || argument.start_with?("solid_queue")
    end
  end

  def env_value(env, key)
    value = env[key]
    return nil if value.nil? || value.empty?

    value
  end
end
