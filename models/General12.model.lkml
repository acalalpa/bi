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
    sql_on: ${movimientos.Cuenta} = ${catalogo_cuentas.cuenta} ;;
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
    type: inner
    sql_on: ${catalogo_cuentas.cliente} = ${clientes_broxel.clave_cliente} ;;
    sql_where: ${clientes_broxel.clave_cliente} NOT IN ('17BRC02313', '20BRC0208', '17BRC02315', '18BRC00188', '17BRC02314') ;;
    relationship: one_to_one
  }
  join: catalogo_clasificacion_clientes {
    type: left_outer
    sql_on: ${catalogo_clasificacion_clientes.codigo} = ${clientes_broxel.clasificacion_ctes_broxel} ;;
    relationship: many_to_one
  }
  join: productos_broxel {
    type: left_outer
    sql_on: ${productos_broxel.codigo} = ${movimientos.Producto} ;;
    relationship: many_to_one
  }
  join: filtros_grl12 {
    type: left_outer
    sql_on: ${movimientos.llave} = ${filtros_grl12.llave} ;;
    relationship: many_to_many
  }

}

explore: prueba_promos_broxel {
  join: filtros_grl12 {
    type: left_outer
    sql_on: ${prueba_promos_broxel.clave_grupo_cliente} = ${filtros_grl12.clave_grupo_cliente} ;;
    relationship: many_to_many
  }


}
