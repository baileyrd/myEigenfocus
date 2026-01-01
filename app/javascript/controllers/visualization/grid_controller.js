import { Controller } from "@hotwired/stimulus"
import { createGrid } from "ag-grid-community"
import "ag-grid-community/styles/ag-grid.css"
import "ag-grid-community/styles/ag-theme-alpine.css"

export default class extends Controller {
  static targets = ["grid"]
  static values = {
    projectId: Number,
    issues: Array,
    statuses: Array,
    types: Array,
    members: Array,
    updatePath: String
  }

  connect() {
    this.gridApi = null
    this.initializeGrid()
  }

  disconnect() {
    if (this.gridApi) {
      this.gridApi.destroy()
    }
  }

  initializeGrid() {
    const columnDefs = this.getColumnDefinitions()
    const rowData = this.issuesValue || []

    const gridOptions = {
      columnDefs: columnDefs,
      rowData: rowData,
      defaultColDef: {
        sortable: true,
        filter: true,
        resizable: true,
        editable: false
      },
      domLayout: 'normal',
      onCellValueChanged: this.onCellValueChanged.bind(this),
      rowSelection: 'multiple',
      animateRows: true,
      enableCellTextSelection: true,
      suppressRowClickSelection: true
    }

    this.gridApi = createGrid(this.gridTarget, gridOptions)
  }

  getColumnDefinitions() {
    return [
      {
        field: 'id',
        headerName: 'ID',
        width: 80,
        pinned: 'left',
        cellRenderer: params => `#${params.value}`,
        filter: 'agNumberColumnFilter'
      },
      {
        field: 'title',
        headerName: 'Title',
        width: 300,
        pinned: 'left',
        editable: true,
        cellStyle: { 'font-weight': '500' }
      },
      {
        field: 'issue_status_id',
        headerName: 'Status',
        width: 140,
        editable: true,
        cellEditor: 'agSelectCellEditor',
        cellEditorParams: {
          values: this.statusesValue.map(s => s.id)
        },
        valueFormatter: params => {
          const status = this.statusesValue.find(s => s.id === params.value)
          return status ? status.name : ''
        },
        cellRenderer: params => {
          const status = this.statusesValue.find(s => s.id === params.value)
          if (!status) return ''
          return `<span class="badge" style="background-color: ${status.color}; color: white; padding: 2px 8px; border-radius: 4px; font-size: 12px;">${status.name}</span>`
        }
      },
      {
        field: 'issue_type_id',
        headerName: 'Type',
        width: 120,
        editable: true,
        cellEditor: 'agSelectCellEditor',
        cellEditorParams: {
          values: this.typesValue.map(t => t.id)
        },
        valueFormatter: params => {
          const type = this.typesValue.find(t => t.id === params.value)
          return type ? type.name : ''
        },
        cellRenderer: params => {
          const type = this.typesValue.find(t => t.id === params.value)
          if (!type) return ''
          return `<span style="color: ${type.color};">${type.icon} ${type.name}</span>`
        }
      },
      {
        field: 'assigned_user_id',
        headerName: 'Assignee',
        width: 150,
        editable: true,
        cellEditor: 'agSelectCellEditor',
        cellEditorParams: {
          values: [null, ...this.membersValue.map(m => m.id)]
        },
        valueFormatter: params => {
          if (!params.value) return 'Unassigned'
          const member = this.membersValue.find(m => m.id === params.value)
          return member ? member.name : ''
        },
        cellRenderer: params => {
          if (!params.value) return '<span style="color: #999;">Unassigned</span>'
          const member = this.membersValue.find(m => m.id === params.value)
          if (!member) return ''
          return `<div style="display: flex; align-items: center; gap: 8px;">
            <div style="width: 24px; height: 24px; border-radius: 50%; background: #3b82f6; color: white; display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: bold;">
              ${member.initials || member.name.charAt(0)}
            </div>
            ${member.name}
          </div>`
        }
      },
      {
        field: 'due_date',
        headerName: 'Due Date',
        width: 140,
        editable: true,
        cellEditor: 'agDateCellEditor',
        valueFormatter: params => params.value ? new Date(params.value).toLocaleDateString() : '',
        filter: 'agDateColumnFilter'
      },
      {
        field: 'created_at',
        headerName: 'Created',
        width: 140,
        valueFormatter: params => new Date(params.value).toLocaleDateString(),
        filter: 'agDateColumnFilter'
      },
      {
        field: 'updated_at',
        headerName: 'Updated',
        width: 140,
        valueFormatter: params => new Date(params.value).toLocaleDateString(),
        filter: 'agDateColumnFilter'
      }
    ]
  }

  async onCellValueChanged(params) {
    const issue = params.data
    const field = params.column.getColId()
    const newValue = params.newValue

    try {
      const csrfToken = document.querySelector('[name="csrf-token"]')?.content

      const response = await fetch(`/projects/${this.projectIdValue}/issues/${issue.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({
          issue: {
            [field]: newValue
          }
        })
      })

      if (!response.ok) {
        throw new Error('Failed to update issue')
      }

      // Show success feedback
      this.showNotification('Issue updated successfully', 'success')
    } catch (error) {
      console.error('Error updating issue:', error)

      // Revert change
      params.node.setDataValue(field, params.oldValue)

      this.showNotification('Failed to update issue', 'error')
    }
  }

  showNotification(message, type) {
    // Simple notification - could be enhanced with a toast library
    console.log(`[${type.toUpperCase()}] ${message}`)

    // Optional: Create a simple toast notification
    const toast = document.createElement('div')
    toast.className = `alert alert-${type === 'success' ? 'success' : 'error'} fixed top-4 right-4 z-50 shadow-lg`
    toast.innerHTML = `<span>${message}</span>`
    toast.style.minWidth = '200px'

    document.body.appendChild(toast)

    setTimeout(() => {
      toast.remove()
    }, 3000)
  }
}
