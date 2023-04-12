connection: "azuresqlbi"

# include all the views
include: "/views/**/*.view"


datagroup: maquila_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  sql_trigger: "SELECT GETUTCDATE() as looker_trigger" # Runs every 6 hours
      persist_for: "6 hours" # Retains data for 6 hours before it is refreshed
      cache_time: "6 hours" # Caches data for 6 hours
      # max_cache_age: "6 hour";;
}

persist_with: maquila_default_datagroup

explore: catalogo_cuentas  {
  join: movimientos {
    type: left_outer
    sql_on: ${catalogo_cuentas.cuenta} = ${movimientos.Cuenta} ;;
    relationship: one_to_many
  }
  join: comercio {
    type: left_outer
    sql_on: ${movimientos.Categoria} = ${comercio.comercio} ;;
    relationship: many_to_one
  }
  join: catalogo_categoria_comercio {
    type: left_outer
    sql_on: ${comercio.categoria} = ${catalogo_categoria_comercio.id} ;;
    relationship: many_to_one
  }
  join: clientes_broxel {
    type: left_outer
    sql_on: ${catalogo_cuentas.cliente} = ${clientes_broxel.clave_cliente} ;;
    sql_where: ${clientes_broxel.clave_cliente} NOT IN ('17BRC02313', '20BRC0208', '17BRC02315', '18BRC00188', '17BRC02314') ;;
    relationship: one_to_many
  }
  join: catalogo_clasificacion_clientes {
    type: left_outer
    sql_on: ${catalogo_clasificacion_clientes.codigo} = ${clientes_broxel.clasificacion_ctes_broxel} ;;
    relationship: one_to_many
  }
  join: catalogo_tipo_transaccion {
    type: left_outer
    sql_on: ${movimientos.Cuenta} = ${catalogo_tipo_transaccion.tipo_transaccion};;
    relationship: one_to_many
  }
}
