class UpdateProcolAtDateFunctionFilterTerminatedProcols < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      DROP FUNCTION IF EXISTS procol_at_date(date);

      CREATE FUNCTION procol_at_date(date_param date)
      RETURNS TABLE(siren VARCHAR(9), date_effet DATE, action_procol TEXT, stade_procol TEXT, libelle_procol TEXT) AS $$
        WITH last_action_procol AS (
          SELECT DISTINCT ON (siren, action_procol)
            siren, date_effet, action_procol, stade_procol, libelle_procol
          FROM osf_procols
          WHERE date_effet <= date_param
          ORDER BY siren, action_procol, date_effet DESC
        )
        SELECT DISTINCT ON (siren)
          siren, date_effet, action_procol, stade_procol, libelle_procol
        FROM last_action_procol
        -- On retire les procédures collectives qui se sont terminées
        WHERE action_procol != 'fin_procedure' AND action_procol != 'inclusion_autre_procedure'
        ORDER BY siren, action_procol; -- action_procol alphabetical order liquidation < redressement < sauvegarde
      $$ LANGUAGE SQL;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS procol_at_date(date);

      CREATE FUNCTION procol_at_date(date_param date)
      RETURNS TABLE(siren VARCHAR(9), date_effet DATE, action_procol TEXT, stade_procol TEXT, libelle_procol TEXT) AS $$
        WITH last_action_procol AS (
          SELECT DISTINCT ON (siren, action_procol)
            siren, date_effet, action_procol, stade_procol, libelle_procol
          FROM osf_procols
          WHERE date_effet <= date_param
          ORDER BY siren, action_procol, date_effet DESC
        )
        SELECT siren, date_effet, action_procol, stade_procol, libelle_procol
        FROM last_action_procol
        WHERE stade_procol != 'fin_procedure';
      $$ LANGUAGE SQL;
    SQL
  end
end
