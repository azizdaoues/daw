# Script PowerShell pour générer des rapports de tests détaillés
param(
    [string]$TestSuite = "all",
    [string]$OutputDir = "reports"
)

# Créer le dossier de sortie s'il n'existe pas
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force
}

# Fonction pour générer un rapport HTML détaillé
function Generate-DetailedReport {
    param(
        [string]$TestSuite,
        [string]$OutputFile
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests - $TestSuite</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .header h1 { margin: 0; font-size: 2.5em; }
        .header p { margin: 5px 0 0 0; opacity: 0.9; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
        .summary-card { background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #007bff; }
        .summary-card.success { border-left-color: #28a745; }
        .summary-card.failure { border-left-color: #dc3545; }
        .summary-card h3 { margin: 0 0 10px 0; color: #333; }
        .summary-card .number { font-size: 2em; font-weight: bold; }
        .test-details { margin-top: 20px; }
        .test-class { background: #f8f9fa; margin: 10px 0; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6; }
        .test-class h3 { margin: 0 0 10px 0; color: #495057; border-bottom: 2px solid #007bff; padding-bottom: 5px; }
        .test-method { margin: 10px 0; padding: 10px; background: white; border-radius: 4px; border-left: 4px solid #28a745; }
        .test-method.failed { border-left-color: #dc3545; background: #fff5f5; }
        .test-method h4 { margin: 0 0 5px 0; color: #333; }
        .test-method p { margin: 5px 0; color: #666; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
        .footer { margin-top: 30px; padding: 20px; background: #f8f9fa; border-radius: 6px; text-align: center; color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 Rapport de Tests - $TestSuite</h1>
            <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
        </div>
        
        <div class="summary">
            <div class="summary-card success">
                <h3>✅ Tests Réussis</h3>
                <div class="number" id="passed-count">0</div>
            </div>
            <div class="summary-card failure">
                <h3>❌ Tests Échoués</h3>
                <div class="number" id="failed-count">0</div>
            </div>
            <div class="summary-card">
                <h3>⏱️ Temps d'Exécution</h3>
                <div class="number" id="execution-time">0s</div>
            </div>
            <div class="summary-card">
                <h3>📊 Taux de Réussite</h3>
                <div class="number" id="success-rate">0%</div>
            </div>
        </div>
        
        <div class="test-details" id="test-details">
            <!-- Les détails des tests seront ajoutés ici -->
        </div>
        
        <div class="footer">
            <p>Rapport généré automatiquement par Jenkins Pipeline</p>
        </div>
    </div>
    
    <script>
        // Script pour mettre à jour les statistiques
        function updateStats() {
            const passedTests = document.querySelectorAll('.test-method:not(.failed)').length;
            const failedTests = document.querySelectorAll('.test-method.failed').length;
            const totalTests = passedTests + failedTests;
            const successRate = totalTests > 0 ? Math.round((passedTests / totalTests) * 100) : 0;
            
            document.getElementById('passed-count').textContent = passedTests;
            document.getElementById('failed-count').textContent = failedTests;
            document.getElementById('success-rate').textContent = successRate + '%';
        }
        
        // Mettre à jour les statistiques au chargement
        document.addEventListener('DOMContentLoaded', updateStats);
    </script>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Rapport détaillé généré: $OutputFile"
}

# Exécuter les tests et générer les rapports
Write-Host "🚀 Démarrage des tests pour la suite: $TestSuite"

if ($TestSuite -eq "all" -or $TestSuite -eq "unit") {
    Write-Host "📋 Exécution des tests unitaires..."
    & vendor\bin\phpunit --testsuite=Unit --log-junit="$OutputDir\unit-tests.xml" --testdox-html="$OutputDir\unit-tests-basic.html" --verbose --colors=always
    Generate-DetailedReport -TestSuite "Unit" -OutputFile "$OutputDir\unit-tests-detailed.html"
}

if ($TestSuite -eq "all" -or $TestSuite -eq "feature") {
    Write-Host "📋 Exécution des tests fonctionnels..."
    & vendor\bin\phpunit --testsuite=Feature --log-junit="$OutputDir\feature-tests.xml" --testdox-html="$OutputDir\feature-tests-basic.html" --verbose --colors=always
    Generate-DetailedReport -TestSuite "Feature" -OutputFile "$OutputDir\feature-tests-detailed.html"
}

Write-Host "✅ Génération des rapports terminée!" 
