import React from 'react';

const ArchitectureDiagram = () => {
  // SVG styling
  const svgStyle = {
    fontFamily: 'Arial, sans-serif',
    fontSize: '12px'
  };
  
  // Colors
  const colors = {
    moduleBackground: '#f0f4f8',
    moduleStroke: '#8da9c4',
    moduleTitle: '#2c3e50',
    arrowStroke: '#8da9c4',
    highlightFill: '#e2eafc',
    highlightStroke: '#5e81ac',
    backgroundGrid: '#f8f9fa',
    coreBackground: '#e0e8f0',
    storageBackground: '#e0f0e8',
    processBg: '#f0e8e0',
    algoBg: '#e8e0f0',
    utilBg: '#f5f5f5',
    interfacesBg: '#e5ffe5'
  };
  
  // Arrow marker definition
  const markerDef = (
    <defs>
      <marker
        id="arrowhead"
        markerWidth="10"
        markerHeight="7"
        refX="9"
        refY="3.5"
        orient="auto"
      >
        <polygon points="0 0, 10 3.5, 0 7" fill={colors.arrowStroke} />
      </marker>
    </defs>
  );
  
  // Module box component
  const ModuleBox = ({ x, y, width, height, title, content, fill, stroke, textColor, fontSize = 12, titleSize = 14 }) => (
    <g>
      <rect
        x={x}
        y={y}
        width={width}
        height={height}
        fill={fill || colors.moduleBackground}
        stroke={stroke || colors.moduleStroke}
        strokeWidth="2"
        rx="5"
        ry="5"
      />
      <text
        x={x + width/2}
        y={y + 20}
        textAnchor="middle"
        fill={textColor || colors.moduleTitle}
        fontWeight="bold"
        fontSize={titleSize}
      >
        {title}
      </text>
      {content && (
        <foreignObject x={x + 10} y={y + 30} width={width - 20} height={height - 40}>
          <div xmlns="http://www.w3.org/1999/xhtml" style={{ fontSize: fontSize + 'px' }}>
            {content}
          </div>
        </foreignObject>
      )}
    </g>
  );
  
  // Connection line component
  const ConnectionLine = ({ x1, y1, x2, y2, label, dashed }) => (
    <g>
      <line
        x1={x1}
        y1={y1}
        x2={x2}
        y2={y2}
        stroke={colors.arrowStroke}
        strokeWidth="1.5"
        strokeDasharray={dashed ? "5,5" : "none"}
        markerEnd="url(#arrowhead)"
      />
      {label && (
        <text
          x={(x1 + x2)/2}
          y={(y1 + y2)/2 - 5}
          textAnchor="middle"
          fill={colors.moduleTitle}
          fontSize="11"
          fontStyle="italic"
          backgroundColor="white"
        >
          <tspan style={{ backgroundColor: 'white', padding: '0 3px' }}>{label}</tspan>
        </text>
      )}
    </g>
  );
  
  // Create a grid background
  const createGrid = () => {
    const gridLines = [];
    const spacing = 20;
    
    for (let i = 0; i < 1200; i += spacing) {
      gridLines.push(
        <line key={`vl-${i}`} x1={i} y1="0" x2={i} y2="900" stroke={colors.backgroundGrid} strokeWidth="1" />
      );
    }
    
    for (let i = 0; i < 900; i += spacing) {
      gridLines.push(
        <line key={`hl-${i}`} x1="0" y1={i} x2="1200" y2={i} stroke={colors.backgroundGrid} strokeWidth="1" />
      );
    }
    
    return gridLines;
  };
  
  return (
    <svg width="100%" height="900" viewBox="0 0 1200 900" style={svgStyle}>
      {markerDef}
      
      {/* Grid background */}
      <g>{createGrid()}</g>
      
      {/* Main containers */}
      <rect x="50" y="50" width="1100" height="800" fill="white" stroke="#ccc" strokeWidth="1" rx="10" ry="10" />
      <text x="60" y="30" fontSize="24" fontWeight="bold" fill="#2c3e50">Base Data Project Framework Architecture</text>
      
      {/* User/External Interface */}
      <ModuleBox 
        x={100} 
        y={100} 
        width={1000} 
        height={80} 
        title="User/External Interface" 
        content={
          <ul style={{ margin: 0, paddingLeft: 20 }}>
            <li><strong>CLI:</strong> Project initialization, commands</li>
            <li><strong>Python API:</strong> Direct library usage</li>
            <li><strong>Configuration:</strong> YAML/JSON configuration files</li>
          </ul>
        }
        fill={colors.interfacesBg}
      />
      
      {/* Core Framework */}
      <ModuleBox 
        x={100} 
        y={210} 
        width={1000} 
        height={560} 
        title="Core Framework" 
        fill={colors.coreBackground}
      />
      
      {/* Data Management */}
      <ModuleBox 
        x={120} 
        y={250} 
        width={400} 
        height={220} 
        title="Data Management" 
        content={
          <div>
            <p><strong>BaseDataManager (Abstract)</strong></p>
            <ul style={{ margin: 0, paddingLeft: 20 }}>
              <li>CSVDataManager</li>
              <li>DBDataManager</li>
              <li>APIDataManager</li>
            </ul>
            <p><strong>DataManagerFactory</strong></p>
            <p><em>Handles primary data access and persistence</em></p>
          </div>
        }
        fill={colors.storageBackground}
      />
      
      {/* Process Management */}
      <ModuleBox 
        x={680} 
        y={250} 
        width={400} 
        height={220} 
        title="Process Management" 
        content={
          <div>
            <p><strong>ProcessManager</strong></p>
            <ul style={{ margin: 0, paddingLeft: 20 }}>
              <li>Decision management</li>
              <li>Stage coordination</li>
              <li>Caching mechanism</li>
              <li>Scenario management</li>
            </ul>
            <p><strong>ProcessStageHandler</strong></p>
            <p><em>Manages multi-stage workflows</em></p>
          </div>
        }
        fill={colors.processBg}
      />
      
      {/* Algorithm Framework */}
      <ModuleBox 
        x={120} 
        y={490} 
        width={400} 
        height={200} 
        title="Algorithm Framework" 
        content={
          <div>
            <p><strong>BaseAlgorithm (Abstract)</strong></p>
            <ul style={{ margin: 0, paddingLeft: 20 }}>
              <li>adapt_data()</li>
              <li>execute_algorithm()</li>
              <li>format_results()</li>
            </ul>
            <p><strong>AlgorithmFactory</strong></p>
            <p><em>Standardizes algorithm implementation</em></p>
          </div>
        }
        fill={colors.algoBg}
      />
      
      {/* Storage Layer (for Intermediate Data) */}
      <ModuleBox 
        x={680} 
        y={490} 
        width={400} 
        height={200} 
        title="Storage Layer (Intermediate Data)" 
        content={
          <div>
            <p><strong>BaseDataContainer (Abstract)</strong></p>
            <ul style={{ margin: 0, paddingLeft: 20 }}>
              <li>MemoryDataContainer</li>
              <li>CSVDataContainer</li>
              <li>DBDataContainer</li>
              <li>HybridDataContainer</li>
            </ul>
            <p><strong>DataContainerFactory</strong></p>
            <p><em>Stores & retrieves intermediate processing results</em></p>
          </div>
        }
        fill={colors.storageBackground}
        stroke={colors.highlightStroke}
        strokeWidth="3"
      />
      
      {/* Utilities */}
      <ModuleBox 
        x={120} 
        y={710} 
        width={960} 
        height={50} 
        title="Utilities" 
        content={
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <span><strong>log_config</strong></span>
            <span><strong>path_helpers</strong></span>
            <span><strong>utils</strong></span>
            <span><strong>helpers</strong></span>
          </div>
        }
        fill={colors.utilBg}
      />
      
      {/* External Sources/Targets */}
      <ModuleBox 
        x={100} 
        y={790} 
        width={1000} 
        height={50} 
        title="External Data Sources/Targets" 
        content={
          <div style={{ display: 'flex', justifyContent: 'space-around' }}>
            <span><strong>CSV Files</strong></span>
            <span><strong>Databases</strong></span>
            <span><strong>APIs</strong></span>
            <span><strong>Cloud Storage</strong></span>
          </div>
        }
        fill={colors.interfacesBg}
      />
      
      {/* Connection lines */}
      
      {/* User interface to components */}
      <ConnectionLine x1={200} y1={180} x2={200} y2={250} label="Initialize" />
      <ConnectionLine x1={400} y1={180} x2={400} y2={250} label="Configure" />
      <ConnectionLine x1={600} y1={180} x2={600} y2={250} label="Execute" />
      <ConnectionLine x1={800} y1={180} x2={800} y2={250} label="Monitor" />
      <ConnectionLine x1={1000} y1={180} x2={1000} y2={250} label="Results" />
      
      {/* Data Management to Process Management */}
      <ConnectionLine x1={520} y1={320} x2={680} y2={320} label="Provides Data" />
      
      {/* Process Management to Algorithm Framework */}
      <ConnectionLine x1={680} y1={420} x2={520} y2={520} label="Executes" />
      
      {/* Process Management to Storage Layer */}
      <ConnectionLine x1={780} y1={470} x2={780} y2={490} label="Stores Results" />
      <ConnectionLine x1={850} y1={490} x2={850} y2={470} label="Retrieves Intermediates" dashed={true} />
      
      {/* Algorithm Framework to Data Management */}
      <ConnectionLine x1={320} y1={490} x2={320} y2={470} label="Uses Core Data" />
      
      {/* Components to Utilities */}
      <ConnectionLine x1={300} y1={690} x2={300} y2={710} label="Uses" dashed={true} />
      <ConnectionLine x1={500} y1={690} x2={500} y2={710} label="Uses" dashed={true} />
      <ConnectionLine x1={700} y1={690} x2={700} y2={710} label="Uses" dashed={true} />
      <ConnectionLine x1={900} y1={690} x2={900} y2={710} label="Uses" dashed={true} />
      
      {/* Data Management to External Sources */}
      <ConnectionLine x1={220} y1={470} x2={220} y2={790} label="Read/Write" />
      <ConnectionLine x1={380} y1={470} x2={380} y2={790} label="Read/Write" />
      
      {/* Storage Layer to External Sources */}
      <ConnectionLine x1={780} y1={690} x2={780} y2={790} label="Store Intermediates" />
      <ConnectionLine x1={900} y1={690} x2={900} y2={790} label="Store Intermediates" />
      
      {/* Legend */}
      <rect x="50" y="860" width="160" height="20" fill={colors.storageBackground} stroke={colors.moduleStroke} rx="3" ry="3" />
      <text x="130" y="874" textAnchor="middle" fontSize="12">Data Management</text>
      
      <rect x="220" y="860" width="160" height="20" fill={colors.processBg} stroke={colors.moduleStroke} rx="3" ry="3" />
      <text x="300" y="874" textAnchor="middle" fontSize="12">Process Management</text>
      
      <rect x="390" y="860" width="160" height="20" fill={colors.algoBg} stroke={colors.moduleStroke} rx="3" ry="3" />
      <text x="470" y="874" textAnchor="middle" fontSize="12">Algorithm Framework</text>
      
      <rect x="560" y="860" width="160" height="20" fill={colors.interfacesBg} stroke={colors.moduleStroke} rx="3" ry="3" />
      <text x="640" y="874" textAnchor="middle" fontSize="12">External Interfaces</text>
      
      <rect x="730" y="860" width="160" height="20" fill={colors.utilBg} stroke={colors.moduleStroke} rx="3" ry="3" />
      <text x="810" y="874" textAnchor="middle" fontSize="12">Utilities</text>
      
      <rect x="900" y="860" width="230" height="20" fill={colors.storageBackground} stroke={colors.highlightStroke} strokeWidth="2" rx="3" ry="3" />
      <text x="1015" y="874" textAnchor="middle" fontSize="12">New Storage Layer (Focus)</text>
    </svg>
  );
};

export default ArchitectureDiagram;
